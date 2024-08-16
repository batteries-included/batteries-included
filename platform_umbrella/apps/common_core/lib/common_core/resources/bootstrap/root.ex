defmodule CommonCore.Resources.BootstrapRoot do
  @moduledoc """
  This is resource generator for resources before our initial bootstrap has put
  anything into kube.

  Anything here can be used as an input for our initial bootstrap.
  """
  alias CommonCore.Resources.Bootstrap.BatteryCore
  alias CommonCore.Resources.Bootstrap.TraditionalServices

  @generator_mappings [
    battery_core: BatteryCore,
    traditional_services: TraditionalServices
  ]

  def materialize(%{batteries: batteries} = state) do
    batteries
    |> Enum.flat_map(fn %{type: battery_type} = system_battery ->
      case Keyword.get(@generator_mappings, battery_type, nil) do
        nil -> %{}
        module -> module.materialize(system_battery, state)
      end
    end)
    |> Map.new()
  end
end
