defmodule CommonCore.Actions.ActionGenerator do
  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.StateSummary
  alias CommonCore.Batteries.SystemBattery

  @callback materialize(SystemBattery.t(), StateSummary.t()) :: list(FreshGeneratedAction.t())
end
