defmodule KubeExt.SystemState.Namespaces do
  import KubeExt.SystemState.Core

  alias KubeExt.SystemState.StateSummary
  alias KubeExt.Defaults

  def core_namespace(%StateSummary{} = state) do
    state
    |> get_battery(:battery_core)
    |> get_config_value(:core_namespace, Defaults.Namespaces.core())
  end

  def base_namespace(%StateSummary{} = state) do
    state
    |> get_battery(:battery_core)
    |> get_config_value(:base_namespace, Defaults.Namespaces.base())
  end

  def istio_namespace(%StateSummary{} = state) do
    state
    |> get_battery(:istio_base)
    |> get_config_value(:namespace, Defaults.Namespaces.istio())
  end

  #
  # User Namespaces
  # These namespaces exist to put stuff that users will
  # run here.
  #
  # Databases
  # Notebooks
  # etc
  def ml_namespace(%StateSummary{} = state) do
    state
    |> get_battery(:ml_core)
    |> get_config_value(:namespace, Defaults.Namespaces.ml())
  end

  def data_namespace(%StateSummary{} = state) do
    state
    |> get_battery(:data)
    |> get_config_value(:namespace, Defaults.Namespaces.data())
  end
end
