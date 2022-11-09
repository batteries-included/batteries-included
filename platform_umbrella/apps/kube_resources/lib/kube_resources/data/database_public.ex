defmodule KubeResources.DatabasePublic do
  alias KubeResources.Database
  alias KubeResources.DataSettings, as: Settings
  alias KubeResources.PostgresPod

  def materialize(battery, state) do
    namespace = Settings.public_namespace(battery.config)

    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :standard end)
    |> Enum.with_index()
    |> Enum.map(fn {cluster, idx} ->
      {cluster_path(cluster, idx), Database.postgres(cluster, battery, state)}
    end)
    |> Map.new()
    |> Map.merge(PostgresPod.per_namespace(namespace))
  end

  defp cluster_path(%{id: id} = _cluster, _idx), do: Path.join("/cluster/", id)
  defp cluster_path(_cluster, idx), do: Path.join("/cluster:idx/", to_string(idx))
end
