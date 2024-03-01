defmodule CommonUI.Components.DatetimeDisplay do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Tooltip

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

  defp full(time), do: time |> ensure_datetime() |> Timex.format!("{ISO:Extended}")
  defp relative(time), do: time |> ensure_datetime() |> Timex.format!("{relative}", :relative)

  defp ensure_datetime(time) when is_binary(time) do
    case Timex.parse(time, "{ISO:Extended}") do
      {:ok, parsed} -> parsed
      _ -> DateTime.utc_now()
    end
  end

  defp ensure_datetime(nil), do: DateTime.utc_now()
  defp ensure_datetime(time), do: time
end
