defmodule KubeResources.Database do
  alias ControlServer.Postgres
  alias KubeRawResources.Database, as: RawDatabase

  def materialize_public(%{} = config) do
    Postgres.normal_clusters()
    |> Enum.map(fn cluster ->
      {"/cluster/" <> cluster.id, RawDatabase.postgres(cluster, config)}
    end)
    |> Enum.into(%{})
  end

  def materialize_internal(%{} = config) do
    Postgres.internal_clusters()
    |> Enum.map(fn cluster ->
      {"/cluster/" <> cluster.id, RawDatabase.postgres(cluster, config)}
    end)
    |> Enum.into(%{})
  end
end
