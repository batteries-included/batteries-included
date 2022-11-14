defmodule KubeExt.SystemState.Namespaces do
  import KubeExt.SystemState.Core

  alias KubeExt.SystemState.StateSummary
  alias KubeExt.Defaults

  def core_namespace(%StateSummary{} = state) do
    state
    |> get_battery(:battery_core)
    |> get_config_value(:namespace, Defaults.Namespaces.core())
  end

  def data_namespace(%StateSummary{} = state) do
    state
    |> get_battery(:data)
    |> get_config_value(:namespace, Defaults.Namespaces.data())
  end

  def istio_namespace(%StateSummary{} = state) do
    state
    |> get_battery(:istio_base)
    |> get_config_value(:namespace, Defaults.Namespaces.istio())
  end

  def ml_namespace(%StateSummary{} = state) do
    state
    |> get_battery(:ml_core)
    |> get_config_value(:namespace, Defaults.Namespaces.ml())
  end

  def loadbalancer_namespace(%StateSummary{} = state) do
    state
    |> get_battery(:metallb)
    |> get_config_value(:namespace, Defaults.Namespaces.loadbalancer())
  end
end
