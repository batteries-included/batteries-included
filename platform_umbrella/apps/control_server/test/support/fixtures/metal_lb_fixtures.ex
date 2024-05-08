defmodule ControlServer.MetalLBFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.MetalLB` context.
  """

  @doc """
  Generate a ip_address_pool.
  """
  def ip_address_pool_fixture(attrs \\ %{}) do
    {:ok, ip_address_pool} =
      attrs
      |> Enum.into(%{
        name: "some-name",
        subnet: "some subnet"
      })
      |> ControlServer.MetalLB.create_ip_address_pool()

    ip_address_pool
  end
end
