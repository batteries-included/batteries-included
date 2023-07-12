defmodule CommonCore.Actions.RootActionGenerator do
  alias CommonCore.StateSummary
  alias CommonCore.Actions.BaseAction

  @default_generator_mappings []

  @spec materialize(StateSummary.t()) :: list(BaseAction.t())
  def materialize(%StateSummary{batteries: batteries} = state) do
    batteries
    |> Enum.map(fn %{type: type} = sb ->
      # Grab the generator for this battery type
      # If there isn't one then return nil
      {sb, Keyword.get(@default_generator_mappings, type, nil)}
    end)
    # Remove any elements with no generator
    |> Enum.filter(fn {_system_battery, gen} -> gen end)
    |> Enum.flat_map(fn {system_battery, generator} ->
      generator.(system_battery, state)
    end)
    |> Enum.filter(& &1)
  end
end
