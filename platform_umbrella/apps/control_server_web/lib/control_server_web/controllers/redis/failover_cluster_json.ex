defmodule ControlServerWeb.RedisInstanceJSON do
  alias CommonCore.Redis.RedisInstance

  @doc """
  Renders a list of redis_instances.
  """
  def index(%{redis_instances: redis_instances}) do
    %{data: for(redis_instance <- redis_instances, do: data(redis_instance))}
  end

  @doc """
  Renders a single redis_instance.
  """
  def show(%{redis_instance: redis_instance}) do
    %{data: data(redis_instance)}
  end

  defp data(%RedisInstance{} = redis_instance) do
    %{
      id: redis_instance.id,
      name: redis_instance.name,
      num_instances: redis_instance.num_instances,
      cpu_requested: redis_instance.cpu_requested,
      memory_requested: redis_instance.memory_requested,
      memory_limits: redis_instance.memory_limits,
      type: redis_instance.type
    }
  end
end
