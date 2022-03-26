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
        memory_request: "some memory_request",
        name: "some name",
        num_redis_instances: 42,
        num_sentinel_instances: 42
      })
      |> ControlServer.Redis.create_failover_cluster()

    failover_cluster
  end
end
