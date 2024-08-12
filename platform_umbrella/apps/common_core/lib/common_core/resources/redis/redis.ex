defmodule CommonCore.Resources.Redis do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "redis-instances"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Redis.RedisInstance
  alias CommonCore.Resources.Builder, as: B

  multi_resource(:redis_instances, battery, state) do
    Enum.map(state.redis_instances, fn redis ->
      redis_resource(redis, battery, state)
    end)
  end

  defp redis_resource(%RedisInstance{instance_type: :standalone} = redis, battery, state) do
    namespace = data_namespace(state)

    spec = %{
      kubernetesConfig: %{
        image: battery.config.redis_image,
        resources: resources(redis)
      }
    }

    :redis
    |> B.build_resource()
    |> B.name(redis_name(redis))
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.owner_label(redis.id)
    |> B.label("sidecar.istio.io/inject", "false")
  end

  defp redis_resource(%RedisInstance{instance_type: :cluster} = redis, battery, state) do
    namespace = data_namespace(state)

    spec = %{
      clusterSize: redis.num_instances,
      kubernetesConfig: %{
        image: battery.config.redis_image,
        resources: resources(redis)
      },
      redisLeader: %{
        readinessProbe: probe(redis),
        livenessProbe: probe(redis),
        pdb: %{
          minAvailable: 1,
          enabled: true
        }
      },
      redisFollower: %{
        readinessProbe: probe(redis),
        livenessProbe: probe(redis),
        pdb: %{
          minAvailable: 1,
          enabled: true
        }
      }
    }

    :redis_cluster
    |> B.build_resource()
    |> B.name(redis_name(redis))
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.owner_label(redis.id)
    |> B.label("sidecar.istio.io/inject", "false")
  end

  defp redis_resource(%RedisInstance{instance_type: :replication} = redis, battery, state) do
    namespace = data_namespace(state)

    spec = %{
      clusterSize: redis.num_instances,
      readinessProbe: probe(redis),
      livenessProbe: probe(redis),
      kubernetesConfig: %{
        image: battery.config.redis_image,
        resources: resources(redis)
      }
    }

    :redis_replication
    |> B.build_resource()
    |> B.name(redis_name(redis))
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> B.owner_label(redis.id)
    |> B.label("sidecar.istio.io/inject", "false")
  end

  defp redis_resource(%RedisInstance{instance_type: _} = _redis, _battery, _state) do
    nil
  end

  defp resources(%RedisInstance{} = redis) do
    requests =
      %{}
      |> maybe_add("cpu", format_cpu(redis.cpu_requested))
      |> maybe_add("memory", redis.memory_requested)

    limits =
      %{}
      |> maybe_add("cpu", format_cpu(redis.cpu_limits))
      |> maybe_add("memory", redis.memory_limits)

    %{}
    |> maybe_add("requests", requests)
    |> maybe_add("limits", limits)
  end

  defp format_cpu(nil), do: nil

  defp format_cpu(cpu) when is_number(cpu) do
    if cpu < 1000 do
      to_string(cpu) <> "m"
    else
      to_string(cpu / 1000)
    end
  end

  defp maybe_add(map, _key, value) when value == %{}, do: map

  defp maybe_add(map, key, value) do
    if value do
      Map.put(map, key, value)
    else
      map
    end
  end

  def redis_name(%RedisInstance{} = redis) do
    "redis-" <> redis.name
  end

  defp probe(_) do
    %{
      failureThreshold: 5,
      initialDelaySeconds: 10,
      periodSeconds: 10,
      successThreshold: 1,
      timeoutSeconds: 5
    }
  end
end
