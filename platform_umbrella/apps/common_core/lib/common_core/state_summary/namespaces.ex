defmodule CommonCore.StateSummary.Namespaces do
  @moduledoc false
  import CommonCore.StateSummary.Core

  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary

  @spec core_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def core_namespace(%StateSummary{} = summary), do: core_config_namespace(summary, :core_namespace)

  @spec base_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def base_namespace(%StateSummary{} = summary), do: core_config_namespace(summary, :base_namespace)

  @spec istio_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def istio_namespace(%StateSummary{} = summary), do: battery_namespace(summary, :istio)

  #
  # User Namespaces
  # These namespaces exist to put stuff that users will
  # run here.
  #
  # Databases
  # Notebooks
  # etc
  @spec ml_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def ml_namespace(%StateSummary{} = summary), do: core_config_namespace(summary, :ml_namespace)

  @spec data_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def data_namespace(%StateSummary{} = summary), do: core_config_namespace(summary, :data_namespace)

  @spec knative_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def knative_namespace(%StateSummary{} = summary), do: battery_namespace(summary, :knative)

  @spec core_config_namespace(CommonCore.StateSummary.t(), atom()) :: binary() | nil
  defp core_config_namespace(summary, key) do
    case battery_core_config(summary) do
      %BatteryCoreConfig{} = config -> get_in(config, [Access.key(key)])
      _ -> nil
    end
  end

  @spec battery_namespace(CommonCore.StateSummary.t(), atom()) :: binary() | nil
  defp battery_namespace(summary, battery) do
    case get_battery(summary, battery) do
      %{config: config} ->
        config.namespace

      _ ->
        nil
    end
  end

  # Given a summary get the BatteryCoreConfig.
  #
  # Return nil if the battery isn't there
  # Return nil if the config isn't there
  # Return nil if the config isn't valid.
  defp battery_core_config(summary) do
    with %SystemBattery{} = sb <- get_battery(summary, :battery_core),
         %BatteryCoreConfig{} = config <- sb.config do
      config
    else
      _ ->
        nil
    end
  end
end
