defmodule KubeResources.Database do
  import KubeResources.RawCluster
  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F

  @exporter_port 9187
  @exporter_port_name "exporter"

  @app_name "postgres-operator"

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

  defp namespace(%{type: :internal} = _cluster, state), do: core_namespace(state)
  defp namespace(%{type: _} = _cluster, state), do: data_namespace(state)

  defp postgres_spec(cluster) do
    %{
      "teamId" => team_name(cluster),
      "numberOfInstances" => num_instances(cluster),
      "postgresql" => %{
        "version" => postgres_version(cluster),
        "parameters" => %{
          "log_destination" => "stderr",
          "logging_collector" => "false",
          "password_encryption" => "scram-sha-256"
        }
      },
      "patroni" => %{"pg_hba" => pg_hba()},
      "volume" => %{
        "size" => storage_size(cluster)
      },
      "users" => spec_users(cluster),
      "databases" => spec_databases(cluster),
      "sidecars" => [
        exporter_sidecar(cluster)
      ]
    }
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
    |> B.namespace(namespace)
    |> B.name(service_name)
    |> B.spec(spec)
    |> add_owner(cluster)
    |> F.require_battery(state, :prometheus)
  end

  def service_monitor(%{} = cluster, _battery, state, role) do
    namespace = namespace(cluster, state)
    cluster_name = full_name(cluster)

    monitor_name = "#{cluster_name}-#{role}"

    spec =
      %{}
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put("selector", %{"matchLabels" => cluster_label_selector(cluster, role)})
      |> Map.put("endpoints", [
        %{
          "port" => @exporter_port_name,
          "interval" => "30s",
          "scheme" => "http",
          "scrapeTimeout" => "10s"
        }
      ])

    B.build_resource(:service_monitor)
    |> B.app_labels("postgres-operator")
    |> B.label("spilo-role", role)
    |> B.namespace(namespace)
    |> B.name(monitor_name)
    |> B.spec(spec)
    |> add_owner(cluster)
    |> F.require_battery(state, :prometheus)
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
              "name" => "postgres.#{cluster_name}.credentials.postgresql.acid.zalan.do",
              "key" => "username"
            }
          }
        },
        %{
          "name" => "DATA_SOURCE_PASS",
          "valueFrom" => %{
            "secretKeyRef" => %{
              "name" => "postgres.#{cluster_name}.credentials.postgresql.acid.zalan.do",
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
end
