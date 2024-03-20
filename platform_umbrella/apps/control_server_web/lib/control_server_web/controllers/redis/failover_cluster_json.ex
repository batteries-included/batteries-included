defmodule ControlServerWeb.FailoverClusterJSON do
  alias CommonCore.Redis.FailoverCluster

  @doc """
  Renders a list of failover_clusters.
  """
  def index(%{failover_clusters: failover_clusters}) do
    %{data: for(failover_cluster <- failover_clusters, do: data(failover_cluster))}
  end

  @doc """
  Renders a single failover_cluster.
  """
  def show(%{failover_cluster: failover_cluster}) do
    %{data: data(failover_cluster)}
  end

  defp data(%FailoverCluster{} = failover_cluster) do
    %{
      id: failover_cluster.id,
      name: failover_cluster.name,
      num_redis_instances: failover_cluster.num_redis_instances,
      num_sentinel_instances: failover_cluster.num_sentinel_instances,
      cpu_requested: failover_cluster.cpu_requested,
      memory_requested: failover_cluster.memory_requested,
      memory_limits: failover_cluster.memory_limits,
      type: failover_cluster.type
    }
  end
end
