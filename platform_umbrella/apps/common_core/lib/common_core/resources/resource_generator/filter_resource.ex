defmodule CommonCore.Resources.FilterResource do
  @moduledoc """
  Filtering resources.

  It can be used at the end of a gen resource pipe, emitting
  nil if the resource shouldn't be sent to kubernetes for some
  reason (For example the inputs aren't there yet, or the
  dependent batteries aren't installed.)
  """
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Batteries

  @spec require_battery(map(), StateSummary.t(), atom() | list(atom())) :: map() | nil
  def require_battery(resource, state, battery_types \\ [])

  def require_battery(resource, state, battery_type) when is_atom(battery_type),
    do: require_battery(resource, state, [battery_type])

  def require_battery(resource, state, battery_types) when is_list(battery_types) do
    if Batteries.batteries_installed?(state, battery_types) do
      resource
    end
  end

  @spec disallow_battery(map(), StateSummary.t(), atom() | list(atom())) :: map() | nil
  def disallow_battery(resource, state, battery_types \\ [])

  def disallow_battery(resource, state, battery_type) when is_atom(battery_type),
    do: disallow_battery(resource, state, [battery_type])

  def disallow_battery(resource, state, battery_types) when is_list(battery_types) do
    if !Batteries.batteries_installed?(state, battery_types) do
      resource
    end
  end

  @spec require_non_empty(map(), Enumerable.t()) :: map() | nil
  def require_non_empty(resource, enumerable)
  def require_non_empty(_resource, nil), do: nil

  def require_non_empty(resource, data) do
    if Enum.empty?(data) do
      nil
    else
      resource
    end
  end

  @spec require(map(), boolean()) :: map() | nil
  def require(resource, boolean)
  def require(resource, true), do: resource
  def require(_, _falsey), do: nil

  @spec require_non_nil(map(), term()) :: map() | nil
  def require_non_nil(_resource, nil), do: nil
  def require_non_nil(resource, _), do: resource
end
