defmodule CommonCore.Resources.CloudnativePGClusters do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "cloudnative-pg-clusters"

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGUser
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Secret
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.PostgresState

  defguardp is_empty(arg) when is_nil(arg) or arg == ""

  multi_resource(:postgres_clusters, battery, state) do
    Enum.map(state.postgres_clusters, fn cluster ->
      cluster_resource(cluster, battery, state)
    end)
  end

  multi_resource(:scheduled_backups, battery, state) do
    Enum.map(state.postgres_clusters, fn cluster ->
      scheduled_backup(cluster, battery, state)
    end)
  end

  multi_resource(:role_secrets, battery, state) do
    Enum.flat_map(state.postgres_clusters, fn cluster ->
      Enum.flat_map(cluster.users, fn user ->
        # Start with the namespace that the cluster is running in
        # aka the cluster has to know it's own passwords
        [PostgresState.cluster_namespace(state, cluster)]
        # Then add in any configured namespaces for the user
        |> Enum.concat(user.credential_namespaces)
        |> Enum.uniq()
        # For every namespace create a secret
        |> Enum.map(fn ns ->
          user_role_secret(battery, state, cluster, user, ns)
        end)
      end)
    end)
  end

  multi_resource(:pod_monitors, battery, state) do
    Enum.map(state.postgres_clusters, fn cluster ->
      cluster_pod_monitor(battery, state, cluster)
    end)
  end

  def cluster_resource(%Cluster{} = cluster, battery, state) do
    db = cluster.database || %{database: "app", owner: "app"}
    cluster_name = cluster_name(cluster)

    spec =
      %{
        instances: cluster.num_instances,
        storage: %{size: Integer.to_string(cluster.storage_size), resizeInUseVolumes: false},
        enableSuperuserAccess: false,
        bootstrap: %{initdb: %{database: db.name, owner: db.owner, dataChecksums: true}},
        postgresql: %{
          parameters: postgres_paramters(cluster)
        },
        affinity: %{
          enablePodAntiAffinity: true,
          topologyKey: "failure-domain.beta.kubernetes.io/zone"
        },
        resources: resources(cluster),

        # Users are called roles in postgres just to confuse
        # the fuck out of us here.
        #
        # Roles also called users in the damn cli are also inheritable
        # bags of permissions.
        #
        # In this case we just use them as users.
        managed: %{
          roles:
            Enum.map(cluster.users, fn user ->
              pg_user_to_pg_role(state, cluster, user)
            end)
        }
      }
      |> maybe_add_certificates(Batteries.batteries_installed?(state, :battery_ca), cluster)
      |> maybe_add_sa_annotations(battery)
      |> maybe_add_backup(battery)

    :cloudnative_pg_cluster
    |> B.build_resource()
    |> B.name(cluster_name)
    |> B.app_labels(cluster_name)
    |> B.component_labels(@app_name)
    |> B.namespace(PostgresState.cluster_namespace(state, cluster))
    |> B.add_owner(cluster)
    |> B.spec(spec)
  end

  defp maybe_add_certificates(spec, predicate, _cluster) when not predicate, do: spec

  defp maybe_add_certificates(spec, _predicate, cluster) do
    client_secret_name = cert_secret_name(cluster, :client)
    server_secret_name = cert_secret_name(cluster, :server)

    Map.put(spec, "certificates", %{
      "clientCASecret" => client_secret_name,
      "replicationTLSSecret" => client_secret_name,
      "serverTLSSecret" => server_secret_name,
      "serverCASecret" => server_secret_name
    })
  end

  defp maybe_add_sa_annotations(spec, %{config: %{service_role_arn: arn}}) when not is_empty(arn) do
    Map.put(spec, :serviceAccountTemplate, %{
      metadata: %{annotations: %{"eks.amazonaws.com/role-arn" => arn}}
    })
  end

  defp maybe_add_sa_annotations(spec, _battery), do: spec

  defp maybe_add_backup(spec, %{config: %{bucket_name: bucket}}) when not is_empty(bucket) do
    Map.put(spec, :backup, %{
      retentionPolicy: "30d",
      barmanObjectStore: %{
        # the backups are stored in a prefix (default: cluster_name) under this path
        destinationPath: "s3://#{bucket}",
        data: %{compression: "snappy"},
        wal: %{compression: "snappy"},
        s3Credentials: %{inheritFromIAMRole: true}
      }
    })
  end

  defp maybe_add_backup(spec, _battery), do: spec

  def scheduled_backup(cluster, battery, state) do
    cluster_name = cluster_name(cluster)

    spec = %{schedule: "0 0 0 * * *", cluster: %{name: cluster_name}}

    :cloudnative_pg_scheduledbackup
    |> B.build_resource()
    |> B.name(cluster_name)
    |> B.app_labels(cluster_name)
    |> B.component_labels(@app_name)
    |> B.namespace(PostgresState.cluster_namespace(state, cluster))
    |> B.add_owner(cluster)
    |> B.spec(spec)
    |> F.require_non_nil(battery.config.bucket_name)
    |> F.require_non_nil(battery.config.service_role_arn)
  end

  defp resources(%Cluster{} = cluster) do
    requests =
      %{}
      |> maybe_add("cpu", format_cpu(cluster.cpu_requested))
      |> maybe_add("memory", cluster.memory_requested)

    limits =
      %{}
      |> maybe_add("cpu", format_cpu(cluster.cpu_limits))
      |> maybe_add("memory", cluster.memory_limits)

    %{}
    |> maybe_add("requests", requests)
    |> maybe_add("limits", limits)
  end

  defp format_cpu(nil), do: nil

  defp format_cpu(cpu) when is_number(cpu) do
    if cpu < 1000 do
      to_string(cpu) <> "m"
    else
      to_string(cpu / 1000)
    end
  end

  defp maybe_add(map, _key, value) when value == %{}, do: map

  defp maybe_add(map, key, value) do
    if value do
      Map.put(map, key, value)
    else
      map
    end
  end

  defp postgres_paramters(_cluster) do
    %{
      "timezone" => "UTC",
      "max_connections" => "200",
      # Autovacuum
      "autovacuum" => "on",
      # Stats for the dashboards
      "pg_stat_statements.max" => "10000",
      "pg_stat_statements.track" => "all",
      "pg_stat_statements.track_utility" => "false",

      # Auto explain long running queries.
      "auto_explain.log_min_duration" => "5s",
      "auto_explain.log_analyze" => "true",
      "auto_explain.log_buffers" => "true",
      "auto_explain.sample_rate" => "0.01",
      "pgaudit.log" => "role, ddl, misc_set",
      "pgaudit.log_catalog" => "off"
    }
  end

  @spec user_role_secret(
          CommonCore.Batteries.SystemBattery.t(),
          CommonCore.StateSummary.t(),
          CommonCore.Postgres.Cluster.t(),
          CommonCore.Postgres.PGUser.t(),
          String.t()
        ) :: map
  def user_role_secret(_battery, state, %Cluster{} = cluster, %PGUser{} = user, namespace) do
    data = Secret.encode(secret_data(state, cluster, user))

    cluster_name = cluster_name(cluster)

    :secret
    |> B.build_resource()
    |> B.name(PostgresState.user_secret(state, cluster, user))
    |> B.app_labels(cluster_name)
    |> B.namespace(namespace)
    |> B.add_owner(cluster)
    |> B.data(data)
  end

  defp cluster_pod_monitor(_battery, state, %Cluster{} = cluster) do
    cluster_name = cluster_name(cluster)

    spec =
      %{}
      |> Map.put("podMetricsEndpoints", [%{"port" => "metrics"}])
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"cnpg.io/cluster" => cluster_name}}
      )

    :monitoring_pod_monitor
    |> B.build_resource()
    |> B.name(cluster_name)
    |> B.app_labels(cluster_name)
    |> B.namespace(PostgresState.cluster_namespace(state, cluster))
    |> B.spec(spec)
    |> B.add_owner(cluster)
    |> F.require_battery(state, :victoria_metrics)
  end

  defp secret_data(state, cluster, user) do
    hostname = PostgresState.read_write_hostname(state, cluster)

    password = PostgresState.password_for_user(state, cluster, user)

    if password == nil do
      %{}
    else
      dsn = "postgresql://#{user.username}:#{password}@#{hostname}/#{cluster.database.name}"
      %{dsn: dsn, username: user.username, password: password, hostname: hostname}
    end
  end

  defp pg_user_to_pg_role(state, %Cluster{} = cluster, user) do
    # TODO(elliott): Figure the UI for this out better.
    # for now this grabs all the roles that are true.
    #
    # Resulting in something like:
    # %{ superuser: true, login: true, name: "elliott", ensure: "present"}
    user.roles
    |> Map.new(&{&1, true})
    |> Map.merge(%{
      name: user.username,
      ensure: "present",
      passwordSecret: %{name: PostgresState.user_secret(state, cluster, user)}
    })
  end

  defp cluster_name(cluster), do: "pg-#{cluster.name}"

  defp cert_secret_name(cluster, type), do: "#{cluster_name(cluster)}-#{type}-cert"

  defp gen_dns_names(state, cluster) do
    Enum.flat_map(~w(rw r ro), fn type ->
      name = "#{cluster_name(cluster)}-#{type}"
      namespace = PostgresState.cluster_namespace(state, cluster)

      [
        "#{name}",
        "#{name}.#{namespace}",
        "#{name}.#{namespace}.svc",
        "#{name}.#{namespace}.svc.cluster.local"
      ]
    end)
  end

  multi_resource(:postgres_certificates, _battery, state) do
    Enum.flat_map(state.postgres_clusters, fn cluster ->
      Enum.flat_map([:server, :client], fn type ->
        [
          cert_resource(cluster, type, state),
          cert_secret_resource(cluster, type, state)
        ]
      end)
    end)
  end

  defp cert_resource(cluster, type, state) do
    name = "#{cluster_name(cluster)}-#{type}"
    namespace = PostgresState.cluster_namespace(state, cluster)

    :certmanager_certificate
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.spec(build_cert_spec(state, cluster, type))
    |> F.require_battery(state, :battery_ca)
  end

  defp cert_secret_resource(cluster, type, state) do
    name = cert_secret_name(cluster, type)
    namespace = PostgresState.cluster_namespace(state, cluster)

    :secret
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.label("cnpg.io/reload", "")
    |> F.require_battery(state, :battery_ca)
  end

  defp build_cert_spec(_state, cluster, type) when type == :client do
    name = cluster_name(cluster)

    %{}
    |> Map.put("commonName", "#{name}-client")
    |> Map.put("usages", ["client auth"])
    |> Map.put("issuerRef", %{"group" => "cert-manager.io", "kind" => "ClusterIssuer", "name" => "battery-ca"})
    |> Map.put("revisionHistoryLimit", 1)
    |> Map.put("secretName", cert_secret_name(cluster, :client))
  end

  defp build_cert_spec(state, cluster, type) when type == :server do
    name = cluster_name(cluster)
    namespace = PostgresState.cluster_namespace(state, cluster)

    %{}
    |> Map.put("commonName", "#{name}.#{namespace}.svc")
    |> Map.put("dnsNames", gen_dns_names(state, cluster))
    |> Map.put("usages", ["server auth"])
    |> Map.put("issuerRef", %{"group" => "cert-manager.io", "kind" => "ClusterIssuer", "name" => "battery-ca"})
    |> Map.put("revisionHistoryLimit", 1)
    |> Map.put("secretName", cert_secret_name(cluster, :server))
  end
end
