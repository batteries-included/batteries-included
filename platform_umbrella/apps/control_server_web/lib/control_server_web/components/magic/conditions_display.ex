defmodule ControlServerWeb.ConditionsDisplay do
  use ControlServerWeb, :html

  attr :conditions, :list, required: true

  def conditions_display(assigns) do
    ~H"""
    <.table id="conditions-table" rows={Enum.sort_by(@conditions, &get_condition_time/1)}>
      <:col :let={condition} label="Type"><%= Map.get(condition, "type", "") %></:col>
      <:col :let={condition} label="Message"><%= Map.get(condition, "message", "") %></:col>
      <:col :let={condition} label="Time"><%= get_condition_time(condition) %></:col>
    </.table>
    """
  end

  defp get_condition_time(condition),
    do: Map.get(condition, "lastTransitionTime", Map.get(condition, "lastUpdateTime", ""))
end
