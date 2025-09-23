defmodule CommonCore.Resources.CloudnativePGClusters do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "cloudnative-pg-clusters"

  import CommonCore.Resources.FieldAccessors
  import CommonCore.Util.String

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGUser
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.CloudNativePGClusterParamters
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Secret
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.FromKubeState
  alias CommonCore.StateSummary.PostgresState

  require Logger

  multi_resource(:postgres_clusters, battery, state) do
    Enum.map(state.postgres_clusters, &cluster_resource(battery, state, &1))
  end

  multi_resource(:scheduled_backups, battery, state) do
    Enum.map(state.postgres_clusters, &scheduled_backup(battery, state, &1))
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
    Enum.map(state.postgres_clusters, &cluster_pod_monitor(battery, state, &1))
  end

  multi_resource(:object_store_backups, battery, state) do
    Enum.map(state.postgres_clusters, &backup(battery, state, &1))
  end

  def cluster_resource(battery, state, %Cluster{} = cluster) do
    db = cluster.database || %{database: "app", owner: "app"}
    cluster_name = cluster_name(cluster)

    spec =
      %{
        instances: cluster.num_instances,
        storage: %{size: Integer.to_string(cluster.storage_size), resizeInUseVolumes: false},
        enableSuperuserAccess: false,
        backup: %{},
        bootstrap: bootstrap(cluster, db),
        externalClusters: external_clusters(state, cluster),
        postgresql: %{
          parameters: CloudNativePGClusterParamters.params(cluster),
          shared_preload_libraries: ["pg_cron", "pg_documentdb_core", "pg_documentdb"]
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
          roles: Enum.map(cluster.users, &pg_user_to_pg_role(state, cluster, &1))
        }
      }
      |> maybe_add_certificates(Batteries.batteries_installed?(state, :battery_ca), cluster)
      |> maybe_add_sa_annotations(state, battery)
      |> maybe_add_plugin_config(cluster, Batteries.batteries_installed?(state, :cloudnative_pg_barman))

    :cloudnative_pg_cluster
    |> B.build_resource()
    |> B.name(cluster_name)
    |> B.app_labels(cluster_name)
    |> B.component_labels(@app_name)
    |> B.namespace(PostgresState.cluster_namespace(state, cluster))
    |> B.add_owner(cluster)
    |> B.spec(spec)
  end

  defp bootstrap(%{restore_from_backup: backup_name}, _db) when not is_empty(backup_name),
    do: %{recovery: %{source: backup_name}}

  defp bootstrap(_cluster, db),
    do: %{
      initdb: %{
        database: db.name,
        owner: db.owner,
        dataChecksums: true,
        postInitSQL: ["CREATE EXTENSION IF NOT EXISTS documentdb CASCADE;"]
      }
    }

  defp external_clusters(state, %{restore_from_backup: backup} = cluster) when not is_empty(backup) do
    namespace = PostgresState.cluster_namespace(state, cluster)

    previous_cluster_name =
      state
      |> FromKubeState.find_state_resource(:cloudnative_pg_backup, namespace, backup)
      |> spec()
      |> get_in(~w(cluster name))

    case previous_cluster_name do
      nil ->
        Logger.error("Failed to get get cluster name from backup: #{inspect(backup)}")
        []

      name ->
        [
          %{
            name: backup,
            plugin: %{
              name: "barman-cloud.cloudnative-pg.io",
              parameters: %{
                barmanObjectName: name,
                serverName: name
              }
            }
          }
        ]
    end
  end

  defp external_clusters(_state, _cluster), do: []

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

  defp maybe_add_sa_annotations(spec, state, battery) do
    settings = get_object_store_settings(battery, state)

    case Map.get(settings, :service_role_arn) do
      nil ->
        spec

      arn ->
        Map.put(spec, :serviceAccountTemplate, %{
          metadata: %{annotations: %{"eks.amazonaws.com/role-arn" => arn}}
        })
    end
  end

  defp maybe_add_plugin_config(spec, %{backup_config: %{type: :object_store}} = cluster, barman_installed?)
       when barman_installed? do
    cluster_name = cluster_name(cluster)

    Map.put(spec, "plugins", [
      %{
        name: "barman-cloud.cloudnative-pg.io",
        isWALArchiver: true,
        parameters: %{barmanObjectName: cluster_name}
      }
    ])
  end

  defp maybe_add_plugin_config(spec, _cluster, _barman_installed?), do: spec

  defp backup(battery, state, %{backup_config: %{type: backup_type}} = cluster) when backup_type == :object_store do
    settings = get_object_store_settings(battery, state)
    bucket = Map.get(settings, :bucket_name)
    cluster_name = cluster_name(cluster)

    spec = %{
      retentionPolicy: "30d",
      configuration: %{
        # the backups are stored in a prefix (default: cluster_name) under this path
        destinationPath: "s3://#{bucket}",
        data: %{compression: "snappy"},
        wal: %{compression: "snappy"},
        s3Credentials: %{inheritFromIAMRole: true}
      }
    }

    :cloudnative_pg_barman_objectstore
    |> B.build_resource()
    |> B.name(cluster_name)
    |> B.namespace(PostgresState.cluster_namespace(state, cluster))
    |> B.add_owner(cluster)
    |> B.app_labels(cluster_name)
    |> B.spec(spec)
    |> F.require_battery(state, :cloudnative_pg_barman)
    |> F.require_non_nil(bucket)
  end

  defp backup(_battery, _state, _cluster), do: nil

  def scheduled_backup(_battery, state, cluster) do
    cluster_name = cluster_name(cluster)

    spec = %{
      schedule: "0 0 0 * * *",
      method: "plugin",
      cluster: %{name: cluster_name},
      pluginConfiguration: %{name: "barman-cloud.cloudnative-pg.io"}
    }

    :cloudnative_pg_scheduledbackup
    |> B.build_resource()
    |> B.name(cluster_name)
    |> B.app_labels(cluster_name)
    |> B.component_labels(@app_name)
    |> B.namespace(PostgresState.cluster_namespace(state, cluster))
    |> B.add_owner(cluster)
    |> B.spec(spec)
    |> F.require_battery(state, :cloudnative_pg_barman)
    |> F.require(cluster.backup_config && cluster.backup_config.type == :object_store)
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

  @spec user_role_secret(
          CommonCore.Batteries.SystemBattery.t(),
          CommonCore.StateSummary.t(),
          Cluster.t(),
          PGUser.t(),
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
    |> then(fn role ->
      # special handling of battery-control-user until we have facilities to upgrade battery config
      if user.username == "battery-control-user", do: Map.put(role, "superuser", true), else: role
    end)
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
      Enum.map([:server, :client], &cert_resource(cluster, &1, state))
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

  defp build_cert_spec(_state, cluster, type) when type == :client do
    name = cluster_name(cluster)

    %{}
    |> Map.put("commonName", "#{name}-client")
    |> Map.put("usages", ["client auth"])
    |> build_cert_spec_common(cluster, type)
  end

  defp build_cert_spec(state, cluster, type) when type == :server do
    name = cluster_name(cluster)
    namespace = PostgresState.cluster_namespace(state, cluster)

    %{}
    |> Map.put("commonName", "#{name}.#{namespace}.svc")
    |> Map.put("dnsNames", gen_dns_names(state, cluster))
    |> Map.put("usages", ["server auth"])
    |> build_cert_spec_common(cluster, type)
  end

  defp build_cert_spec_common(spec, cluster, type) do
    spec
    |> Map.put("issuerRef", %{
      "group" => "cert-manager.io",
      "kind" => "ClusterIssuer",
      "name" => "battery-ca"
    })
    |> Map.put("revisionHistoryLimit", 1)
    |> Map.put("secretName", cert_secret_name(cluster, type))
    # allow cert_manager to manage the secret with the correct labels
    |> Map.put(
      "secretTemplate",
      %{} |> B.managed_indirect_labels() |> B.label("cnpg.io/reload", "") |> Map.get("metadata")
    )
  end

  defp get_object_store_settings(battery, state) do
    # if barman battery isn't installed, just return an empty config
    case Batteries.get_battery(state, :cloudnative_pg_barman) do
      nil ->
        %{}

      # use the barman config if it's set, otherwise cnpg config
      barman_battery ->
        barman_battery.config
        |> Map.from_struct()
        |> Enum.reject(fn
          {_k, nil} -> true
          _ -> false
        end)
        |> Map.new()
        |> then(&Map.merge(battery.config, &1))
        |> Map.take(~w(service_role_arn bucket_name)a)
    end
  end
end
