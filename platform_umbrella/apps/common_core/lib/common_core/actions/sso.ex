defmodule CommonCore.Actions.SSO do
  @moduledoc false

  @behaviour CommonCore.Actions.ActionGenerator

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary

  @spec materialize(SystemBattery.t(), StateSummary.t()) :: list(FreshGeneratedAction.t() | nil)
  def materialize(%SystemBattery{} = _system_battery, %StateSummary{} = _state_summary) do
    [ping()]
  end

  defp ping, do: %FreshGeneratedAction{action: :ping, type: :realm, value: %{}}
end
