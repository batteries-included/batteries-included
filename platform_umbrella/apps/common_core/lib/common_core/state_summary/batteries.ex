defmodule CommonCore.StateSummary.Batteries do
  @moduledoc """
    Utilities for manipulating and querying battery information from a state summary.
  """
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Hosts

  @doc """
  Get the battery from the summary matching type.
  """
  def get_battery(%StateSummary{} = summary, type, default \\ nil) do
    Enum.find(summary.batteries, default, &(&1.type == type))
  end

  @doc """
  Generate a map of battery type to host.

  Filters out any types that don't have a host.
  """
  @spec hosts_by_battery_type(StateSummary.t()) :: map()
  def hosts_by_battery_type(%StateSummary{batteries: batteries} = state) do
    batteries
    |> Enum.map(fn %SystemBattery{type: type} -> {type, Hosts.hosts_for_battery(state, type)} end)
    |> Enum.filter(&(elem(&1, 1) != nil))
    |> Map.new()
  end

  @doc """
  Generate a map of battery type to host.

  Includes battery types with nil host.
  """
  @spec all_hosts_by_battery_type(StateSummary.t()) :: map()
  def all_hosts_by_battery_type(%StateSummary{batteries: batteries} = state) do
    Map.new(batteries, fn %SystemBattery{type: type} -> {type, Hosts.hosts_for_battery(state, type)} end)
  end

  @doc """
  Generate a map of batteries keyed by type allowing easy access via e.g. `by_type(summary).istio`.
  """
  @spec by_type(StateSummary.t()) :: %{atom() => SystemBattery.t()}
  def by_type(%StateSummary{batteries: batteries} = _state) do
    Enum.reduce(batteries, %{}, fn battery, acc -> Map.put(acc, battery.type, battery) end)
  end

  @doc """
  A filtering function that matches a battery by its type. Useful for Enum.filter/2 and Enum.reject/2
  """
  @spec battery_matches_type(SystemBattery.t(), atom()) :: boolean()
  def battery_matches_type(%SystemBattery{type: type}, desired_type), do: type == desired_type

  @doc """
  Determines whether the given battery type(s) are installed.
  """
  @spec batteries_installed?(StateSummary.t(), atom()) :: boolean()
  def batteries_installed?(%StateSummary{} = state, battery_type) when is_atom(battery_type),
    do: batteries_installed?(state, [battery_type])

  @spec batteries_installed?(StateSummary.t(), list()) :: boolean()
  def batteries_installed?(%StateSummary{} = state, battery_types) when is_list(battery_types) do
    installed = MapSet.new(state.batteries, & &1.type)
    Enum.all?(battery_types, &MapSet.member?(installed, &1))
  end

  def sso_installed?(%StateSummary{} = state), do: batteries_installed?(state, [:sso])
  def keycloak_installed?(%StateSummary{} = state), do: batteries_installed?(state, [:keycloak])
  def victoria_metrics_installed?(%StateSummary{} = state), do: batteries_installed?(state, [:victoria_metrics])
end
