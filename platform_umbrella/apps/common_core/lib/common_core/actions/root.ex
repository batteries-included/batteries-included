defmodule CommonCore.Actions.RootActionGenerator do
  @moduledoc false
  alias CommonCore.Actions.BatteryCore
  alias CommonCore.Actions.CoreClient
  alias CommonCore.Actions.Forgejo
  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Actions.Grafana
  alias CommonCore.Actions.Kiali
  alias CommonCore.Actions.Knative
  alias CommonCore.Actions.Notebooks
  alias CommonCore.Actions.Smtp4dev
  alias CommonCore.Actions.SSO
  alias CommonCore.Actions.VictoriaMetrics
  alias CommonCore.Actions.VMAgent
  alias CommonCore.StateSummary

  @default_generator_mappings [
    battery_core: [BatteryCore, CoreClient],
    forgejo: [Forgejo],
    grafana: [Grafana],
    kiali: [Kiali],
    knative: [Knative],
    notebooks: [Notebooks],
    smtp4dev: [Smtp4dev],
    sso: [SSO],
    vm_agent: [VMAgent],
    victoria_metrics: [VictoriaMetrics]
  ]

  @spec materialize(StateSummary.t()) :: list(FreshGeneratedAction.t())
  def materialize(%StateSummary{batteries: batteries} = state) do
    batteries
    |> Enum.flat_map(fn %{type: type} = sb ->
      # Grab the generator for this battery type
      # If there isn't one then return nil
      Enum.map(Keyword.get(@default_generator_mappings, type, []), fn gen ->
        {sb, gen}
      end)
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
