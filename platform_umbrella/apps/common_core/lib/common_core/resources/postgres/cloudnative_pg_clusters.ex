defmodule CommonCore.Resources.CloudnativePGClusters do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "cloudnative-pg-clusters"

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGUser
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Secret
  alias CommonCore.StateSummary.PostgresState

  multi_resource(:postgres_clusters, battery, state) do
    Enum.map(state.postgres_clusters, fn cluster ->
      cluster_resource(cluster, battery, state)
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
          user_role_secret(
            battery,
            state,
            cluster,
            user,
            ns
          )
        end)
      end)
    end)
  end

  multi_resource(:pod_monitors, battery, state) do
    Enum.map(state.postgres_clusters, fn cluster ->
      cluster_pod_monitor(battery, state, cluster)
    end)
  end

  def cluster_resource(%Cluster{} = cluster, _battery, state) do
    db = cluster.database || %{database: "app", owner: "app"}

    :cloudnative_pg_cluster
    |> B.build_resource()
    |> B.name(cluster.name)
    |> B.namespace(PostgresState.cluster_namespace(state, cluster))
    |> B.add_owner(cluster)
    |> B.spec(%{
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
    })
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

    :secret
    |> B.build_resource()
    |> B.name(PostgresState.user_secret(state, cluster, user))
    |> B.namespace(namespace)
    |> B.add_owner(cluster)
    |> B.data(data)
  end

  defp cluster_pod_monitor(_battery, state, %Cluster{name: cluster_name} = cluster) do
    spec =
      %{}
      |> Map.put("podMetricsEndpoints", [%{"port" => "metrics"}])
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name,
            "cnpg.io/cluster" => cluster_name
          }
        }
      )

    :monitoring_pod_monitor
    |> B.build_resource()
    |> B.name("pg-cloudnative-" <> cluster_name)
    |> B.namespace(PostgresState.cluster_namespace(state, cluster))
    |> B.spec(spec)
    |> B.add_owner(cluster)
    |> F.require_battery(state, :victoria_metrics)
  end

  defp secret_data(state, cluster, user) do
    hostname = PostgresState.read_write_hostname(state, cluster)
    dsn = "postgresql://#{user.username}:#{user.password}@#{hostname}"
    %{dsn: dsn, username: user.username, password: user.password, hostname: hostname}
  end

  defp pg_user_to_pg_role(state, %Cluster{} = cluster, user) do
    # TODO(elliott): Figure the UI for this out better.
    # for now this grabs all the roles that are true.
    #
    # Resulting in something like:
    # %{ superuser: true, login: true, name: "elliott", ensure: "present"}
    user.roles
    |> Enum.map(&{&1, true})
    |> Map.new()
    |> Map.merge(%{
      name: user.username,
      ensure: "present",
      passwordSecret: %{name: PostgresState.user_secret(state, cluster, user)}
    })
  end
end
