defmodule ControlServerWeb.ConditionsDisplay do
  @moduledoc false
  use ControlServerWeb, :html

  attr :conditions, :list, required: true
  attr :empty, :boolean, default: nil, required: false

  def conditions_display(%{empty: nil} = assigns) do
    conditions = Map.get(assigns, :conditions, [])

    assigns =
      Map.put(
        assigns,
        :empty,
        Enum.all?(conditions, fn c ->
          m = c["message"] || nil
          m == nil || m == ""
        end)
      )

    conditions_display(assigns)
  end

  def conditions_display(%{empty: true} = assigns) do
    ~H"""
    <.h2 class="flex items-center">
      Conditions - <span class="text-base text-gray-500 pt-1 pl-3">no outstanding messages!</span>
    </.h2>
    """
  end

  def conditions_display(assigns) do
    ~H"""
    <.h2>Conditions</.h2>
    <.table rows={Enum.sort_by(@conditions, &get_condition_time/1, :desc)}>
      <:col :let={condition} label="Type"><%= Map.get(condition, "type", "") %></:col>
      <:col :let={condition} label="Message"><%= Map.get(condition, "message", "") %></:col>
      <:col :let={condition} label="Time">
        <%= Timex.format!(get_condition_time(condition), "{RFC822z}") %>
      </:col>
    </.table>
    """
  end

  defp get_condition_time(condition) do
    condition
    |> Map.get_lazy("lastTransitionTime", fn -> Map.get(condition, "lastUpdateTime", "") end)
    |> Timex.parse!("{ISO:Extended:Z}")
  end
end
