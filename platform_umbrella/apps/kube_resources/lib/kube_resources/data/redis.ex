defmodule KubeResources.Redis do
  @moduledoc false
  use KubeExt.IncludeResource,
    crd: "priv/manifests/redis/databases.spotahome.com_redisfailovers.yaml"

  alias ControlServer.Redis
  alias ControlServer.Redis.FailoverCluster
  alias KubeExt.Builder, as: B
  alias KubeRawResources.DataSettings

  @app "redisoperator"

  def materialize(config) do
    redis_failover_clusters(config)
  end

  def redis_failover_clusters(config) do
    Redis.list_failover_clusters()
    |> Enum.map(fn cluster ->
      {"/failover_cluster/" <> cluster.id, redis_failover_cluster(cluster, config)}
    end)
    |> Enum.into(%{})
  end

  defp cluster_namespace(%FailoverCluster{type: :internal} = _cluster, config),
    do: DataSettings.namespace(config)

  defp cluster_namespace(%FailoverCluster{type: _} = _cluster, config),
    do: DataSettings.public_namespace(config)

  def redis_failover_cluster(%FailoverCluster{} = cluster, config) do
    namespace = cluster_namespace(cluster, config)
    spec = failover_spec(cluster)

    B.build_resource(:redis_failover)
    |> B.namespace(namespace)
    |> B.name(cluster.name)
    |> B.app_labels(@app)
    |> B.spec(spec)
    |> B.owner_label(cluster.id)
  end

  defp failover_spec(%FailoverCluster{} = cluster) do
    %{
      "sentinel" => %{
        "replicas" => FailoverCluster.num_sentinel_instances(cluster)
      },
      "redis" => %{
        "replicas" => FailoverCluster.num_redis_instances(cluster)
      }
    }
  end
end
