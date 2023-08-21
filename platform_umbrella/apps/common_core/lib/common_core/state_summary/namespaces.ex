defmodule CommonCore.StateSummary.Namespaces do
  import CommonCore.StateSummary.Core

  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary

  @spec core_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def core_namespace(%StateSummary{} = summary) do
    case battery_core_config(summary) do
      config = %BatteryCoreConfig{} -> config.core_namespace
      _ -> nil
    end
  end

  @spec base_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def base_namespace(%StateSummary{} = summary) do
    case battery_core_config(summary) do
      config = %BatteryCoreConfig{} -> config.base_namespace
      _ -> nil
    end
  end

  @spec istio_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def istio_namespace(%StateSummary{} = summary) do
    case get_battery(summary, :istio) do
      nil ->
        nil

      battery ->
        battery.config.namespace
    end
  end

  #
  # User Namespaces
  # These namespaces exist to put stuff that users will
  # run here.
  #
  # Databases
  # Notebooks
  # etc
  @spec ml_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def ml_namespace(%StateSummary{} = summary) do
    case battery_core_config(summary) do
      config = %BatteryCoreConfig{} -> config.ml_namespace
      _ -> nil
    end
  end

  @spec data_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def data_namespace(%StateSummary{} = summary) do
    case battery_core_config(summary) do
      config = %BatteryCoreConfig{} -> config.data_namespace
      _ -> nil
    end
  end

  @spec knative_namespace(CommonCore.StateSummary.t()) :: binary() | nil
  def knative_namespace(%StateSummary{} = summary) do
    case get_battery(summary, :knative_serving) do
      %{config: config} ->
        config.namesapce

      _ ->
        nil
    end
  end

  # Given a summary get the BatteryCorConfig.
  #
  # Return nil if the battery isn' there
  # Return nil if the config isn't there
  # Return nil if the config isn't valid.
  defp battery_core_config(summary) do
    with sb = %SystemBattery{} <- get_battery(summary, :battery_core),
         config = %BatteryCoreConfig{} <- sb.config do
      config
    else
      _ ->
        nil
    end
  end
end
