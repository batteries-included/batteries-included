defmodule CommonCore.Actions.RootActionGenerator do
  alias CommonCore.StateSummary
  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Actions.SSO

  @default_generator_mappings [
    sso: SSO
  ]

  @spec materialize(StateSummary.t()) :: list(FreshGeneratedAction.t())
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
      generator.materialize(system_battery, state)
    end)
    # Remove anything nil or false.
    |> Enum.filter(& &1)
  end
end
