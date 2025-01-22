defmodule ControlServerWeb.ConditionsDisplay do
  @moduledoc false
  use ControlServerWeb, :html

  attr :conditions, :list, required: true
  attr :empty, :boolean, default: nil, required: false
  attr :variant, :string, default: "gray", required: false
  attr :class, :string, default: nil, required: false

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

  def conditions_display(%{conditions: []} = assigns) do
    ~H"""
    <.panel variant={@variant} title="Conditions" class={@class}>
      <.light_text>No outstanding messages!</.light_text>
    </.panel>
    """
  end

  def conditions_display(assigns) do
    ~H"""
    <.panel variant={@variant} title="Conditions" class={@class}>
      <.table
        id="conditions-display-table"
        rows={Enum.sort_by(@conditions, &get_condition_time/1, :desc)}
      >
        <:col :let={condition} label="Type">{Map.get(condition, "type", "")}</:col>
        <:col :let={condition} label="Message">{Map.get(condition, "message", "")}</:col>
        <:col :let={condition} label="Time">
          <.relative_display time={get_condition_time(condition)} />
        </:col>
      </.table>
    </.panel>
    """
  end

  defp get_condition_time(condition) do
    {:ok, date_time, _} =
      condition
      |> Map.get_lazy("lastTransitionTime", fn -> Map.get(condition, "lastUpdateTime", "") end)
      |> DateTime.from_iso8601()

    date_time
  end
end
