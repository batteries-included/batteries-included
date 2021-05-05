defmodule ControlServer.Services.Database do
  @moduledoc """
  Module for dealing with all the databases for batteries included.
  """

  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster
  alias ControlServer.Services
  alias ControlServer.Services.PostgresOperator
  alias ControlServer.Settings.DatabaseSettings

  import ControlServer.FileExt

  @default_path "/database/base"
  @default_config %{}

  def default_config, do: @default_config

  def activate(path \\ @default_path),
    do: Services.update_active!(true, path, :database, @default_config)

  def deactivate(path \\ @default_path),
    do: Services.update_active!(false, path, :database, @default_config)

  def active?(path \\ @default_path), do: Services.active?(path)

  def materialize(%{} = config) do
    static = %{
      "/0/postgres_crd" => read_yaml("postgres_operator-crds.yaml", :exported),
      "/0/namespace" => namespace(config)
    }

    body =
      PostgresOperator.materialize(config)
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
        "battery-managed" => "True",
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
