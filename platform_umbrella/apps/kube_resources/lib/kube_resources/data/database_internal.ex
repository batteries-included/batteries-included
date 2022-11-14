defmodule KubeResources.DatabaseInternal do
  import KubeExt.SystemState.Namespaces

  alias KubeResources.Database
  alias KubeResources.PostgresPod

  @spec materialize(
          atom | %{:config => map, optional(any) => any},
          atom | %{:postgres_clusters => any, optional(any) => any}
        ) :: map
  def materialize(battery, state) do
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :internal end)
    |> Enum.with_index()
    |> Enum.map(fn {cluster, idx} ->
      {cluster_path(cluster, idx), Database.postgres(cluster, battery, state)}
    end)
    |> Map.new()
    |> Map.merge(PostgresPod.per_namespace(core_namespace(state)))
  end

  defp cluster_path(%{id: id} = _cluster, _idx), do: Path.join("/internal_cluster/", id)
  defp cluster_path(_cluster, idx), do: Path.join("/internal_cluster:idx/", to_string(idx))
end
