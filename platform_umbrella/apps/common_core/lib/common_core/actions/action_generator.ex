defmodule CommonCore.Actions.ActionGenerator do
  @moduledoc false
  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary

  @callback materialize(SystemBattery.t(), StateSummary.t()) :: list(FreshGeneratedAction.t())
end
