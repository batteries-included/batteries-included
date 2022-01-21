defmodule KubeResources.Database do
  alias ControlServer.Postgres
  alias KubeRawResources.Database, as: RawDatabase

  def materialize(%{} = config) do
    clusters =
      Postgres.list_clusters()
      |> Enum.map(fn cluster ->
        {"/3/cluster/" <> cluster.id, RawDatabase.postgres(cluster, config)}
      end)
      |> Map.new()

    config |> RawDatabase.materialize() |> Map.merge(clusters)
  end
end
