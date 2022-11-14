defmodule KubeResources.Redis do
  @moduledoc false
  use KubeExt.IncludeResource,
    crd: "priv/manifests/redis/databases.spotahome.com_redisfailovers.yaml"

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  @app_name "redisoperator"

  def materialize(battery, state) do
    redis_failover_clusters(battery, state)
  end

  def redis_failover_clusters(battery, state) do
    state.redis_clusters
    |> Enum.with_index()
    |> Enum.map(fn {cluster, idx} ->
      {cluster_path(cluster, idx), redis_failover_cluster(cluster, battery, state)}
    end)
    |> Enum.into(%{})
  end

  defp cluster_path(%{id: id} = _cluster, _idx), do: "/redis/cluster/#{id}"
  defp cluster_path(_cluster, idx), do: "/redis/cluster:idx/#{idx}"

  defp cluster_namespace(%{type: :internal} = _cluster, _battery, state),
    do: core_namespace(state)

  defp cluster_namespace(%{type: _} = _cluster, _battery, state),
    do: data_namespace(state)

  def redis_failover_cluster(%{} = cluster, battery, state) do
    namespace = cluster_namespace(cluster, battery, state)
    spec = failover_spec(cluster)

    B.build_resource(:redis_failover)
    |> B.namespace(namespace)
    |> B.name(cluster.name)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
    |> add_owner(cluster)
  end

  defp add_owner(resource, %{id: id} = _cluster), do: B.owner_label(resource, id)
  defp add_owner(resource, _), do: resource

  defp failover_spec(%{} = cluster) do
    %{
      "sentinel" => %{"replicas" => cluster.num_sentinel_instances},
      "redis" => %{"replicas" => cluster.num_redis_instances}
    }
  end
end
