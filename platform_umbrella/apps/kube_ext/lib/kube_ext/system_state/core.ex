defmodule KubeExt.SystemState.Core do
  alias KubeExt.SystemState.StateSummary

  def get_battery(%StateSummary{} = state, type) do
    Enum.find(state.batteries, &(&1.type == type))
  end

  def get_config_value(nil = _battery, _key, default), do: default

  def get_config_value(%{} = battery, key, default) do
    case get_in(battery, [Access.key!(:config), Access.key!(key)]) do
      nil -> default
      value -> value
    end
  end

  def get_config_value(_, _key, default), do: default
end
