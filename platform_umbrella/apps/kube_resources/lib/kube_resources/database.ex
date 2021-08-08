defmodule KubeResources.Database do
  import KubeResources.FileExt

  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster
  alias KubeResources.DatabaseSettings
  alias KubeResources.PostgresOperator

  def materialize(%{} = config) do
    static = %{
      "/0/postgres_crd" => read_yaml("postgres/postgres_operator-crds.yaml", :base),
      "/0/namespace" => namespace(config)
    }

    body =
      config
      |> PostgresOperator.materialize()
      |> Enum.map(fn {key, value} -> {"/1/body" <> key, value} end)
      |> Map.new()

    clusters =
      Postgres.list_clusters()
      |> Enum.map(fn cluster ->
        {"/3/cluster/" <> cluster.id, postgres(cluster, config)}
      end)
      |> Map.new()

    %{} |> Map.merge(static) |> Map.merge(body) |> Map.merge(clusters)
  end

  defp postgres(%Cluster{} = cluster, config) do
    namespace = DatabaseSettings.namespace(config)
    team = "default"

    %{
      "kind" => "postgresql",
      "apiVersion" => "acid.zalan.do/v1",
      "metadata" => %{
        "namespace" => namespace,
        "battery/managed" => "True",
        "name" => team <> "-" <> cluster.name
      },
      "spec" => %{
        "teamId" => "default",
        "numberOfInstances" => cluster.num_instances,
        "postgresql" => %{
          "version" => cluster.postgres_version
        },
        "volume" => %{
          "size" => cluster.size
        }
      }
    }
  end

  defp namespace(config) do
    ns = DatabaseSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Namespace",
      "metadata" => %{
        "name" => ns
      }
    }
  end
end
