defmodule KubeRawResources.Database do
  import KubeExt.Yaml

  alias KubeExt.Builder, as: B

  alias KubeRawResources.DatabaseSettings
  alias KubeRawResources.PostgresOperator

  @postgres_crd_path "priv/manifests/postgres/postgres_operator-crds.yaml"
  @exporter_port 9187
  @exporter_port_name "exporter"

  defp postgres_crd_content, do: unquote(File.read!(@postgres_crd_path))

  def postgres_crd do
    yaml(postgres_crd_content())
  end

  def postgres(%{} = cluster, config) do
    namespace = DatabaseSettings.namespace(config)

    %{
      "kind" => "postgresql",
      "apiVersion" => "acid.zalan.do/v1",
      "metadata" => %{
        "namespace" => namespace,
        "battery/managed" => "True",
        "name" => name(cluster)
      },
      "spec" => %{
        "teamId" => "default",
        "numberOfInstances" => cluster.num_instances,
        "postgresql" => %{
          "version" => cluster.postgres_version
        },
        "volume" => %{
          "size" => cluster.size
        },
        "sidecars" => [
          exporter_sidecar()
        ]
      }
    }
  end

  defp name(%{} = cluster) do
    team_name = "default"
    "#{team_name}-#{cluster.name}"
  end

  def metrics_service(%{} = cluster, config, role) do
    namespace = DatabaseSettings.namespace(config)
    label_name = DatabaseSettings.cluster_name_label(config)
    cluster_name = name(cluster)

    selector = cluster |> cluster_label_selector(config, role) |> Map.put("application", "spilo")

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

    service_name = "postgres-#{cluster_name}-#{role}-mon"

    B.build_resource(:service)
    |> B.app_labels("postgres-operator")
    |> B.label(label_name, cluster_name)
    |> B.label("spilo-role", role)
    |> B.namespace(namespace)
    |> B.name(service_name)
    |> B.spec(spec)
  end

  defp cluster_label_selector(%{} = cluster, config, role) do
    cluster_name = name(cluster)
    label_name = DatabaseSettings.cluster_name_label(config)

    %{
      label_name => cluster_name,
      "spilo-role" => role
    }
  end

  def service_monitor(%{} = cluster, config, role) do
    namespace = DatabaseSettings.namespace(config)
    cluster_name = name(cluster)
    label_name = DatabaseSettings.cluster_name_label(config)

    monitor_name = "postgres-#{cluster_name}-#{role}"

    spec =
      %{}
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put("selector", %{"matchLabels" => cluster_label_selector(cluster, config, role)})
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
    |> B.label(label_name, cluster_name)
    |> B.label("spilo-role", role)
    |> B.namespace(namespace)
    |> B.name(monitor_name)
    |> B.spec(spec)
  end

  defp exporter_sidecar do
    %{
      "name" => "metrics-exporter",
      "image" => "quay.io/prometheuscommunity/postgres-exporter",
      "ports" => [
        %{
          "name" => @exporter_port_name,
          "containerPort" => @exporter_port,
          "protocol" => "TCP"
        }
      ],
      "resources" => %{
        "limits" => %{"cpu" => "200m", "memory" => "256M"},
        "requests" => %{"cpu" => "100m", "memory" => "256M"}
      },
      "env" => [
        %{"name" => "DATA_SOURCE_URI", "value" => "$(POD_NAME)/postgres?sslmode=disable"},
        %{"name" => "DATA_SOURCE_USER", "value" => "$(POSTGRES_USER)"},
        %{"name" => "DATA_SOURCE_PASS", "value" => "$(POSTGRES_PASSWORD)"}
      ]
    }
  end

  defp bootstrap_clusters(config) do
    config
    |> DatabaseSettings.bootstrap_clusters()
    |> Enum.map(fn cluster -> postgres(cluster, config) end)
  end

  def materialize(%{} = config) do
    body =
      config
      |> PostgresOperator.materialize()
      |> Enum.map(fn {key, value} -> {"/1/body" <> key, value} end)
      |> Map.new()

    %{
      "/0/postgres_crd" => postgres_crd()
    }
    |> Map.merge(body)
    |> Map.merge(%{"/9/boostrap_clusters" => bootstrap_clusters(config)})
  end
end
