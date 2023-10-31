defmodule CommonUI.DatetimeDisplay do
  @moduledoc false
  use CommonUI.Component

  import CommonUI.Tooltip

  attr :time, :any, required: true

  def relative_display(assigns) do
    ~H"""
    <.hover_tooltip>
      <:tooltip>
        <%= full(@time) %>
      </:tooltip>
      <%= relative(@time) %>
    </.hover_tooltip>
    """
  end

  defp full(time), do: Timex.format!(time, "{ISO:Extended}")
  defp relative(time), do: Timex.format!(time, "{relative}", :relative)
end
