defmodule ControlServer.Services.Database do
  @moduledoc """
  Module for dealing with all the databases for batteries included.
  """

  alias ControlServer.Postgres
  alias ControlServer.Repo
  alias ControlServer.Services.BaseService
  alias ControlServer.Services.PostgresOperator
  alias ControlServer.Settings.DatabaseSettings

  import Ecto.Query, only: [from: 2]
  import ControlServer.FileExt

  @postgres_default_path "/database/postgres_operator"
  @default_config %{}

  def default_config, do: @default_config

  def activate do
    set_or_update_active(true, @postgres_default_path)
  end

  def deactivate do
    set_or_update_active(false, @postgres_default_path)
  end

  defp set_or_update_active(active, path) do
    query =
      from(bs in BaseService,
        where: bs.root_path == ^path
      )

    changes = %{is_active: active}

    case(Repo.one(query)) do
      # Not found create a new one
      nil ->
        %BaseService{
          is_active: active,
          root_path: path,
          service_type: :database,
          config: @default_config
        }

      base_service ->
        base_service
    end
    |> BaseService.changeset(changes)
    |> Repo.insert_or_update()
  end

  def active? do
    true ==
      Repo.one(
        from(bs in BaseService,
          where: bs.root_path == ^@postgres_default_path,
          select: bs.is_active
        )
      )
  end

  def materialize(%{} = config) do
    static = %{
      "/0/setup/postgres_crd" => read_yaml("postgresql.crd.yaml", :postgres),
      "/0/setup/postgres_team_crd" => read_yaml("postgresteam.crd.yaml", :postgres),
      "/0/setup/postgres_config_crd" => read_yaml("operatorconfiguration.crd.yaml", :postgres),
      "/0/setup/namespace" => namespace(config),
      "/1/setup/account" => PostgresOperator.service_account(config),
      "/1/setup/cluster_role" => PostgresOperator.cluster_role(config),
      "/1/setup/cluster_role_bind" => PostgresOperator.cluster_role_bind(config),
      "/1/setup/pod_cluster_role" => PostgresOperator.pod_cluster_role(config),
      "/1/setup/pod_cluster_role_bind" => PostgresOperator.pod_cluster_role_bind(config),
      "/2/config" => PostgresOperator.config(config),
      "/2/operator" => PostgresOperator.deployment(config)
    }

    clusters =
      Postgres.list_clusters()
      |> Enum.map(fn cluster ->
        {"/3/cluster/" <> cluster.id, PostgresOperator.postgres(cluster, config)}
      end)
      |> Map.new()

    %{} |> Map.merge(static) |> Map.merge(clusters)
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
