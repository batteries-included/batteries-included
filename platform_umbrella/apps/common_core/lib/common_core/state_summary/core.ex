defmodule CommonCore.StateSummary.Core do
  @moduledoc false
  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Defaults
  alias CommonCore.ET.StableVersionsReport
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Batteries

  def get_battery_core(%StateSummary{} = summary), do: Batteries.get_battery(summary, :battery_core)

  @spec config_field(StateSummary.t(), atom()) :: any() | nil
  def config_field(summary, key) do
    case battery_core_config(summary) do
      %BatteryCoreConfig{} = config -> Map.get(config, key)
      _ -> nil
    end
  end

  # Given a summary get the BatteryCoreConfig.
  #
  # Return nil if the battery isn't there
  # Return nil if the config isn't there
  # Return nil if the config isn't valid.
  defp battery_core_config(summary) do
    with %SystemBattery{} = sb <- get_battery_core(summary),
         %BatteryCoreConfig{} = config <- sb.config do
      config
    else
      _ ->
        nil
    end
  end

  def controlserver_image(%StateSummary{} = summary) do
    if upgrade_time?(summary) do
      stable_control_image(summary)
    else
      Defaults.Images.control_server_image()
    end
  end

  defp stable_control_image(%StateSummary{stable_versions_report: %StableVersionsReport{} = report} = _summary) do
    report.control_server
  end

  defp stable_control_image(_summary) do
    Defaults.Images.control_server_image()
  end

  def upgrade_time?(%StateSummary{captured_at: nil} = _summary), do: false

  def upgrade_time?(%StateSummary{captured_at: captured_at} = summary) do
    # When computing what image to use we use the snapshot time
    # This makes it deterministic and repeatable
    day_of_week = Date.day_of_week(captured_at) - 1
    config = battery_core_config(summary)

    day_ok = Enum.at(config.upgrade_days_of_week, day_of_week) || false
    hour_ok = config.upgrade_start_hour <= captured_at.hour && captured_at.hour < config.upgrade_end_hour

    day_ok && hour_ok
  end

  def upgrade_days_of_week(%StateSummary{} = summary) do
    config = battery_core_config(summary)
    Enum.zip(~w(monday tuesday wednesday thursday friday saturday sunday)a, config.upgrade_days_of_week)
  end
end
