defmodule KubeResources.DatabaseInternal do
  alias KubeResources.Database
  alias KubeResources.PostgresPod

  alias KubeResources.DataSettings, as: Settings

  @spec materialize(
          atom | %{:config => map, optional(any) => any},
          atom | %{:postgres_clusters => any, optional(any) => any}
        ) :: map
  def materialize(battery, state) do
    namespace = Settings.namespace(battery.config)

    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :internal end)
    |> Enum.with_index()
    |> Enum.map(fn {cluster, idx} ->
      {cluster_path(cluster, idx), Database.postgres(cluster, battery, state)}
    end)
    |> Map.new()
    |> Map.merge(PostgresPod.per_namespace(namespace))
  end

  defp cluster_path(%{id: id} = _cluster, _idx), do: Path.join("/internal_cluster/", id)
  defp cluster_path(_cluster, idx), do: Path.join("/internal_cluster:idx/", to_string(idx))
end
