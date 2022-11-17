defmodule KubeExt.SystemState.Monitoring do
  import KubeExt.SystemState.Core

  alias KubeExt.Defaults
  alias KubeExt.SystemState.StateSummary

  def kubelet_service(%StateSummary{} = state) do
    state
    |> get_battery(:prometheus_operator)
    |> get_config_value(:kubelet_service, Defaults.Monitoring.kubelet_service())
  end
end
