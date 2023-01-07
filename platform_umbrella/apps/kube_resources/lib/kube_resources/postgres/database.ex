defmodule KubeResources.Database do
  import CommonCore.SystemState.Namespaces
  import CommonCore.SystemState.FromKubeState

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F
  alias KubeExt.Secret

  @exporter_port 9187
  @exporter_port_name "exporter"

  @app_name "postgres-database"

  @pg_hba [
    ["local", "all", "all", "trust"],
    ["host", "all", "all", "127.0.0.1/32", "scram-sha-256"],
    ["host", "all", "all", "::1/128", "scram-sha-256"],
    ["hostssl", "replication", "standby", "all", "scram-sha-256"],

    # This line is added to allow postgres_exporter to attach since it can't use ssl yet.
    # Certs aren't correct.
    ["hostnossl", "all", "postgres", "0.0.0.0/0", "scram-sha-256"],
    ["hostssl", "all", "postgres", "0.0.0.0/0", "scram-sha-256"],
    ["hostssl", "all", "all", "all", "scram-sha-256"],
    ["hostnossl", "all", "all", "all", "scram-sha-256"],
    ["hostnossl", "all", "all", "all", "reject"]
  ]

  def postgres(%{} = cluster, _battery, state) do
    spec = postgres_spec(cluster)

    B.build_resource(:postgresql)
    |> B.namespace(namespace(cluster, state))
    |> B.name(full_name(cluster))
    |> B.app_labels(@app_name)
    |> B.label("sidecar.istio.io/inject", "false")
    |> B.spec(spec)
    |> add_owner(cluster)
  end

  def metrics_service(%{} = cluster, _battery, state, role) do
    namespace = namespace(cluster, state)
    cluster_name = full_name(cluster)

    selector = cluster |> cluster_label_selector(role) |> Map.put("application", "spilo")

    spec =
      %{}
      |> Map.put("selector", selector)
      |> B.ports([
        %{
          "name" => @exporter_port_name,
          "port" => @exporter_port,
          "targetPort" => @exporter_port_name
        }
      ])

    service_name = "#{cluster_name}-#{role}-mon"

    B.build_resource(:service)
    |> B.app_labels(@app_name)
    |> B.label("spilo-role", role)
    |> B.label("monitor-cluster", cluster_name)
    |> B.namespace(namespace)
    |> B.name(service_name)
    |> B.spec(spec)
    |> add_owner(cluster)
    |> F.require_battery(state, :victoria_metrics)
  end

  def service_monitor(%{} = cluster, _battery, state, role) do
    namespace = namespace(cluster, state)
    cluster_name = full_name(cluster)

    monitor_name = "#{cluster_name}-#{role}"

    spec =
      %{}
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put("selector", %{
        "matchLabels" => %{"monitor-cluster" => cluster_name, "spilo-role" => role}
      })
      |> Map.put("endpoints", [
        %{
          "port" => @exporter_port_name,
          "interval" => "30s",
          "scheme" => "http",
          "scrapeTimeout" => "10s"
        }
      ])

    B.build_resource(:monitoring_service_monitor)
    |> B.app_labels(@app_name)
    |> B.label("spilo-role", role)
    |> B.namespace(namespace)
    |> B.name(monitor_name)
    |> B.spec(spec)
    |> add_owner(cluster)
    |> F.require_battery(state, :victoria_metrics)
  end

  def credential_copies(cluster, _battery, state) do
    cluster
    |> Map.get(:credential_copies, [])
    |> Enum.map(fn pg_credential_copy ->
      source_namespace = namespace(cluster, state)
      secret_name = secret_name(cluster, pg_credential_copy.username)

      with %{} = _dest_namespace <-
             find_state_resource(state, :namespace, pg_credential_copy.namespace),
           %{"data" => %{}} = source_secret <-
             find_state_resource(state, :secret, source_namespace, secret_name) do
        cred_copy(cluster, pg_credential_copy, source_secret, state)
      else
        _ ->
          nil
      end
    end)
    |> Enum.reject(fn r -> r == nil end)
  end

  defp cred_copy(cluster, pg_cred_copy, source_secret, state) do
    secret_name = secret_name(cluster, pg_cred_copy.username)
    source_data = extract_secret_data(source_secret)

    B.build_resource(:secret)
    |> B.name(secret_name)
    |> B.namespace(pg_cred_copy.namespace)
    |> add_owner(cluster)
    |> B.data(credential_copy_spec(cluster, pg_cred_copy, source_data, state))
  end

  defp exporter_sidecar(cluster) do
    cluster_name = full_name(cluster)

    %{
      "name" => "metrics-exporter",
      "image" => "quay.io/prometheuscommunity/postgres-exporter:v0.11.1",
      "ports" => [
        %{
          "name" => @exporter_port_name,
          "containerPort" => @exporter_port,
          "protocol" => "TCP"
        }
      ],
      "resources" => %{
        "limits" => %{"memory" => "256M"},
        "requests" => %{"cpu" => "100m", "memory" => "256M"}
      },
      "env" => [
        %{"name" => "DATA_SOURCE_URI", "value" => "#{cluster_name}?sslmode=disable"},
        %{
          "name" => "DATA_SOURCE_USER",
          "valueFrom" => %{
            "secretKeyRef" => %{
              "name" => secret_name(cluster, "postgres"),
              "key" => "username"
            }
          }
        },
        %{
          "name" => "DATA_SOURCE_PASS",
          "valueFrom" => %{
            "secretKeyRef" => %{
              "name" => secret_name(cluster, "postgres"),
              "key" => "password"
            }
          }
        },
        %{
          "name" => "PG_EXPORTER_AUTO_DISCOVER_DATABASES",
          "value" => "true"
        }
      ]
    }
  end

  defp postgres_spec(cluster) do
    %{
      "teamId" => cluster.team_name,
      "numberOfInstances" => cluster.num_instances,
      "postgresql" => %{
        "version" => cluster.postgres_version,
        "parameters" => %{
          "log_destination" => "stderr",
          "logging_collector" => "false",
          "password_encryption" => "scram-sha-256"
        }
      },
      "patroni" => %{"pg_hba" => pg_hba()},
      "volume" => %{
        "size" => cluster.storage_size
      },
      "users" => spec_users(cluster),
      "databases" => spec_databases(cluster),
      "sidecars" => [
        exporter_sidecar(cluster)
      ]
    }
  end

  defp credential_copy_spec(_cluster, %{format: :user_password} = _cc, source_data, _state) do
    Secret.encode(source_data)
  end

  defp credential_copy_spec(cluster, %{format: :user_password_host} = _cc, source_data, state) do
    %{}
    |> Map.put("username", Map.fetch!(source_data, "username"))
    |> Map.put("password", Map.fetch!(source_data, "password"))
    |> Map.put("hostname", hostname(cluster, state))
    |> Secret.encode()
  end

  defp credential_copy_spec(cluster, %{format: :dsn} = _cc, source_data, state) do
    username = Map.fetch!(source_data, "username")
    pass = Map.fetch!(source_data, "password")
    hostname = hostname(cluster, state)

    %{}
    |> Map.put("dsn", "postgresql://#{username}:#{pass}@#{hostname}")
    |> Secret.encode()
  end

  defp namespace(%{type: :internal} = _cluster, state), do: base_namespace(state)
  defp namespace(%{type: _} = _cluster, state), do: data_namespace(state)

  defp full_name(%{} = cluster) do
    "#{cluster.team_name}-#{cluster.name}"
  end

  defp secret_name(%{} = cluster, username) do
    "#{username}.#{cluster.team_name}-#{cluster.name}.credentials.postgresql"
  end

  defp hostname(cluster, state) do
    namespace = namespace(cluster, state)
    "#{cluster.team_name}-#{cluster.name}.#{namespace}.svc"
  end

  defp spec_users(%{} = cluster) do
    cluster
    |> Map.get(:users, [])
    |> Enum.map(fn u -> {u.username, u.roles} end)
    |> Map.new()
  end

  defp spec_databases(%{} = cluster) do
    cluster
    |> Map.get(:databases, [])
    |> Enum.map(fn c -> {c.name, c.owner} end)
    |> Map.new()
  end

  defp pg_hba do
    Enum.map(@pg_hba, fn spec -> Enum.join(spec, "\t") end)
  end

  defp add_owner(resource, %{id: id} = _cluster), do: B.owner_label(resource, id)
  defp add_owner(resource, _), do: resource

  defp cluster_label_selector(%{} = cluster, role) do
    cluster_name = full_name(cluster)

    %{
      "cluster-name" => cluster_name,
      "spilo-role" => role
    }
  end

  defp extract_secret_data(resource) do
    resource |> Map.get("data", %{}) |> Secret.decode!()
  end
end
