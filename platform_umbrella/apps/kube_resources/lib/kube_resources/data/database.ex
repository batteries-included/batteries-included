defmodule KubeResources.Database do
  alias ControlServer.Postgres
  alias KubeRawResources.Database, as: RawDatabase
  alias KubeRawResources.DataSettings, as: Settings
  alias KubeRawResources.PostgresPod

  def materialize_public(%{} = config) do
    namespace = Settings.public_namespace(config)

    Postgres.normal_clusters()
    |> Enum.map(fn cluster ->
      {"/cluster/" <> cluster.id, RawDatabase.postgres(cluster, config)}
    end)
    |> Map.new()
    |> Map.merge(PostgresPod.per_namespace(namespace))
  end

  def materialize_internal(%{} = config) do
    Postgres.internal_clusters()
    |> Enum.map(fn cluster ->
      {"/cluster/" <> cluster.id, RawDatabase.postgres(cluster, config)}
    end)
    |> Map.new()
  end
end
