defmodule CommonCore.Resources.Redis do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "redis-operator"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B

  multi_resource(:redis_failover_cluster, battery, state) do
    Enum.map(state.redis_clusters, fn cluster ->
      spec = failover_spec(cluster)
      namespace = cluster_namespace(cluster, battery, state)

      :redis_failover
      |> B.build_resource()
      |> B.namespace(namespace)
      |> B.name(cluster.name)
      |> B.spec(spec)
      |> add_owner(cluster)
    end)
  end

  defp cluster_namespace(%{type: :internal} = _cluster, _battery, state), do: core_namespace(state)

  defp cluster_namespace(%{type: _} = _cluster, _battery, state), do: data_namespace(state)

  defp add_owner(resource, %{id: nil} = _cluster), do: resource
  defp add_owner(resource, %{id: id} = _cluster), do: B.owner_label(resource, id)
  defp add_owner(resource, _), do: resource

  defp failover_spec(%{} = cluster) do
    %{
      "sentinel" => %{"replicas" => cluster.num_sentinel_instances},
      "redis" => %{"replicas" => cluster.num_redis_instances}
    }
  end
end
