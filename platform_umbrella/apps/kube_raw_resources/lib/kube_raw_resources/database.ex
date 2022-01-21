defmodule KubeRawResources.Database do
  import KubeExt.Yaml

  alias KubeRawResources.DatabaseSettings
  alias KubeRawResources.PostgresOperator

  @postgres_crd_path "priv/manifests/postgres/postgres_operator-crds.yaml"

  defp postgres_crd_content, do: unquote(File.read!(@postgres_crd_path))

  def postgres_crd do
    yaml(postgres_crd_content())
  end

  def postgres(%{} = cluster, config) do
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
