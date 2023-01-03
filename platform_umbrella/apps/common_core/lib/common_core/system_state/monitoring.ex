defmodule CommonCore.SystemState.Monitoring do
  import CommonCore.SystemState.Core

  alias CommonCore.Defaults
  alias CommonCore.SystemState.StateSummary

  def kubelet_service(%StateSummary{} = state) do
    state
    |> get_battery(:prometheus_operator)
    |> get_config_value(:kubelet_service, Defaults.Monitoring.kubelet_service())
  end
end
