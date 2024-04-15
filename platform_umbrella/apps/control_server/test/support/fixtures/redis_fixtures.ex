defmodule ControlServer.RedisFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.Redis` context.
  """

  @doc """
  Generate a failover_cluster.
  """
  def failover_cluster_fixture(attrs \\ %{}) do
    {:ok, failover_cluster} =
      attrs
      |> Enum.into(%{
        name: "some-name",
        type: :standard,
        virtual_size: nil,
        memory_limits: 100,
        memory_requested: 90,
        cpu_limits: 101,
        cpu_requested: 91,
        num_redis_instances: 42,
        num_sentinel_instances: 43
      })
      |> ControlServer.Redis.create_failover_cluster()

    Map.put(failover_cluster, :virtual_size, nil)
  end
end
