defmodule KubeResources.Database do
  alias ControlServer.Postgres
  alias KubeExt.Builder, as: B
  alias KubeRawResources.Database, as: RawDatabase
  alias KubeRawResources.DatabaseSettings
  alias KubeRawResources.PostgresOperator

  def materialize_public(%{} = config) do
    Postgres.normal_clusters()
    |> Enum.map(fn cluster ->
      {"/cluster/" <> cluster.id, RawDatabase.postgres(cluster, config)}
    end)
    |> Enum.into(%{})
    |> Map.merge(PostgresOperator.materialize_public(config))
    |> Map.merge(%{
      "/namesapce" => public_namespace(config)
    })
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

  defp public_namespace(config) do
    namespace = DatabaseSettings.public_namespace(config)

    B.build_resource(:namespace)
    |> B.name(namespace)
    |> B.app_labels("postgres-operator")
  end
end
