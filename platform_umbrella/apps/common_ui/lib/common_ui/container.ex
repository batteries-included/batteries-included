defmodule CommonUI.Container do
  @moduledoc false
  use CommonUI.Component

  @breakpoints ~w(sm md lg xl 2xl)a

  attr :columns, :any, default: [sm: 1, lg: 2, xl: 4]
  attr :gaps, :any, default: [sm: 4, lg: 6]
  attr :class, :any, default: nil

  slot :inner_block

  @doc """
   Renders a grid layout container component.
   The `columns` attribute defines the number of columns for each breakpoint.
   The `gaps` attribute defines the gap size between columns for each breakpoint.
   The `class` attribute allows passing additional classes.
  """
  def grid(assigns) do
    ~H"""
    <div class={build_class([column_class(@columns), gap_class(@gaps), "grid", @class])}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :gaps, :any, default: [sm: 4, lg: 6]
  slot :inner_block

  def flex(assigns) do
    ~H"""
    <div class={build_class([gap_class(@gaps), "flex", @class])}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp column_class(nil = _column), do: []
  defp column_class(columns) when is_number(columns), do: nil |> single_column_class(columns) |> List.wrap()
  defp column_class(columns) when is_binary(columns), do: nil |> single_column_class(columns) |> List.wrap()
  defp column_class(columns), do: to_class(columns, &single_column_class/2)

  defp gap_class(nil = _gap), do: []
  defp gap_class(gap) when is_number(gap), do: nil |> single_gap_class(gap) |> List.wrap()
  defp gap_class(gap) when is_binary(gap), do: nil |> single_gap_class(gap) |> List.wrap()
  defp gap_class(gaps), do: to_class(gaps, &single_gap_class/2)

  defp to_class(break_points, fun) do
    num_breakpoints = Enum.count(break_points)

    break_points
    |> Enum.sort_by(fn {breakpoint, _} -> Enum.find_index(@breakpoints, fn b -> b == breakpoint end) || 100 end)
    |> Enum.with_index()
    |> Enum.map(fn
      {{_breakpoint, num}, idx} when idx + 1 == num_breakpoints -> fun.(nil, num)
      {{breakpoint, num}, _idx} -> fun.(breakpoint, num)
    end)
  end

  defp single_column_class(nil = _breakpoint, num) do
    "grid-cols-#{num}"
  end

  defp single_column_class(breakpoint, num) do
    "#{breakpoint}:grid-cols-#{num}"
  end

  defp single_gap_class(nil = _breakpoint, num) do
    "gap-#{num}"
  end

  defp single_gap_class(breakpoint, num) do
    "#{breakpoint}:gap-#{num}"
  end
end
