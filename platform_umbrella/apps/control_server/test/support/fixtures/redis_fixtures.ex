defmodule ControlServer.RedisFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.Redis` context.
  """

  @doc """
  Generate a redis_instance.
  """
  def redis_instance_fixture(attrs \\ %{}) do
    {:ok, redis_instance} =
      attrs
      |> Enum.into(%{
        type: :standard,
        virtual_size: nil,
        memory_limits: 100,
        memory_requested: 90,
        cpu_limits: 101,
        cpu_requested: 91,
        num_instances: 42
      })
      |> ControlServer.Redis.create_redis_instance()

    Map.put(redis_instance, :virtual_size, nil)
  end
end
