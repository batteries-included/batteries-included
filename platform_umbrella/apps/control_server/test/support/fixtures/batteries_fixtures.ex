defmodule ControlServer.BatteriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.Batteries` context.
  """

  @doc """
  Generate a system_battery.
  """
  def system_battery_fixture(attrs \\ %{}) do
    {:ok, system_battery} =
      attrs
      |> Enum.into(%{
        config: %{__type__: :istio_istiod},
        group: :net_sec,
        type: :istio_istiod
      })
      |> ControlServer.Batteries.create_system_battery()

    system_battery
  end
end
