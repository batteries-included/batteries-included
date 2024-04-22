defmodule CommonCore.StateSummary.Core do
  @moduledoc false
  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary

  def get_battery(%StateSummary{} = summary, type) do
    Enum.find(summary.batteries, &(&1.type == type))
  end

  @spec config_field(CommonCore.StateSummary.t(), atom()) :: any() | nil
  def config_field(summary, key) do
    case battery_core_config(summary) do
      %BatteryCoreConfig{} = config -> get_in(config, [Access.key(key)])
      _ -> nil
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
