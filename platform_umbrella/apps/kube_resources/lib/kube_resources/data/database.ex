defmodule KubeResources.Database do
  alias ControlServer.Postgres
  alias KubeRawResources.Database, as: RawDatabase
  alias KubeRawResources.PostgresOperator

  def materialize_public(%{} = config) do
    Postgres.normal_clusters()
    |> Enum.map(fn cluster ->
      {"/cluster/" <> cluster.id, RawDatabase.postgres(cluster, config)}
    end)
    |> Enum.into(%{})
    |> Map.merge(PostgresOperator.materialize_public(config))
  end

  def materialize_internal(%{} = config) do
    Postgres.internal_clusters()
    |> Enum.map(fn cluster ->
      {"/cluster/" <> cluster.id, RawDatabase.postgres(cluster, config)}
    end)
    |> Enum.into(%{})
    |> Map.merge(PostgresOperator.materialize_internal(config))
  end

  def materialize_common(%{} = config) do
    PostgresOperator.materialize_common(config)
  end
end
