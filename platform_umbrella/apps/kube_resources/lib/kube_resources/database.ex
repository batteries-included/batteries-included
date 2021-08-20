defmodule KubeResources.Database do
  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster
  alias KubeResources.DatabaseSettings
  alias KubeResources.PostgresOperator

  @postgres_crd_path "priv/manifests/postgres/postgres_operator-crds.yaml"

  def materialize(%{} = config) do
    static = %{
      "/0/postgres_crd" => yaml(postgres_crd_content())
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

  defp postgres_crd_content, do: unquote(File.read!(@postgres_crd_path))

  defp yaml(content) do
    content
    |> YamlElixir.read_all_from_string!()
    |> Enum.map(&KubeExt.Hashing.decorate_content_hash/1)
  end
end
