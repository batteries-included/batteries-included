defmodule KubeResources.Redis do
  @moduledoc false
  use KubeExt.IncludeResource,
    crd: "priv/manifests/redis/databases.spotahome.com_redisfailovers.yaml"

  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  @app_name "redisoperator"

  def redis_failover_clusters(battery, state) do
    Enum.map(state.redis_clusters, fn cluster ->
      spec = failover_spec(cluster)
      namespace = cluster_namespace(cluster, battery, state)

      B.build_resource(:redis_failover)
      |> B.namespace(namespace)
      |> B.name(cluster.name)
      |> B.app_labels(@app_name)
      |> B.spec(spec)
      |> add_owner(cluster)
    end)
  end

  defp cluster_namespace(%{type: :internal} = _cluster, _battery, state),
    do: core_namespace(state)

  defp cluster_namespace(%{type: _} = _cluster, _battery, state),
    do: data_namespace(state)

  defp add_owner(resource, %{id: id} = _cluster), do: B.owner_label(resource, id)
  defp add_owner(resource, _), do: resource

  defp failover_spec(%{} = cluster) do
    %{
      "sentinel" => %{"replicas" => cluster.num_sentinel_instances},
      "redis" => %{"replicas" => cluster.num_redis_instances}
    }
  end
end
