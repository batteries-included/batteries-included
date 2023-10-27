defmodule CommonCore.Actions.RootActionGenerator do
  @moduledoc false
  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Actions.Gitea
  alias CommonCore.Actions.Grafana
  alias CommonCore.Actions.Kiali
  alias CommonCore.Actions.Smtp4dev
  alias CommonCore.Actions.SSO
  alias CommonCore.Actions.VMAgent
  alias CommonCore.StateSummary

  @default_generator_mappings [
    gitea: Gitea,
    grafana: Grafana,
    kiali: Kiali,
    smtp4dev: Smtp4dev,
    sso: SSO,
    vm_agent: VMAgent
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
