defmodule KubeExt.FilterResource do
  @moduledoc """
  So this module named `KubeExt.FilterResource` is there for...

  Filtering resources.

  It can be used at the end of a gen resource pipe, emitting
  nil if the resource shouldn't be sent to kubernetes for some
  reason (For example the inputs aren't there yet, or the
  dependent batteries aren't installed.)
  """

  def require_battery(resource, state, battery_types \\ [])

  def require_battery(resource, state, battery_type) when is_atom(battery_type),
    do: require_battery(resource, state, [battery_type])

  def require_battery(resource, state, battery_types) when is_list(battery_types) do
    case batteries_installed?(state, battery_types) do
      true -> resource
      _ -> nil
    end
  end

  def require_non_empty(resource, data) do
    if Enum.empty?(data) do
      nil
    else
      resource
    end
  end

  def batteries_installed?(state, battery_type) when is_atom(battery_type),
    do: batteries_installed?(state, [battery_type])

  def batteries_installed?(state, battery_types) when is_list(battery_types) do
    installed = state.batteries |> Enum.map(& &1.type) |> MapSet.new()
    Enum.all?(battery_types, fn bt -> MapSet.member?(installed, bt) end)
  end
end
