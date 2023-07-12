defmodule CommonCore.Actions.ActionGenerator do
  alias CommonCore.Actions.BaseAction
  alias CommonCore.StateSummary
  alias CommonCore.Batteries.SystemBattery

  @callback materialize(SystemBattery.t(), StateSummary.t()) :: list(BaseAction.t())
end
