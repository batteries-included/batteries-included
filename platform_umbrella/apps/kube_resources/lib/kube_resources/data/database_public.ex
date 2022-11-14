defmodule KubeResources.DatabasePublic do
  import KubeExt.SystemState.Namespaces

  alias KubeResources.Database
  alias KubeResources.PostgresPod

  def materialize(battery, state) do
    namespace = data_namespace(state)

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
