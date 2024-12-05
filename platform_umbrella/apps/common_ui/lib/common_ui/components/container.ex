defmodule CommonUI.Components.Container do
  @moduledoc false
  use CommonUI, :component

  @breakpoints ~w(sm md lg xl 2xl)

  attr :variant, :string, values: ["col-2"]
  attr :columns, :any, default: %{"sm" => 1, "lg" => 2, "xl" => 2, "2xl" => 4}
  attr :gaps, :any, default: %{"sm" => 4, "lg" => 6}
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block

  @doc """
   Renders a grid layout container component.
   The `columns` attribute defines the number of columns for each breakpoint.

   This allows us to address all breakpoints with a single
   attribute. Listed below so that tailwind doesn't reap the grid col classes.

   grid-cols-1
   grid-cols-2
   grid-cols-3
   grid-cols-4
   grid-cols-5
   grid-cols-6
   grid-cols-7
   grid-cols-8
   grid-cols-9
   grid-cols-10
   grid-cols-11
   grid-cols-12

   sm:grid-cols-1
   sm:grid-cols-2
   sm:grid-cols-3
   sm:grid-cols-4
   sm:grid-cols-5
   sm:grid-cols-6
   sm:grid-cols-7
   sm:grid-cols-8
   sm:grid-cols-9
   sm:grid-cols-10
   sm:grid-cols-11
   sm:grid-cols-12

   md:grid-cols-1
   md:grid-cols-2
   md:grid-cols-3
   md:grid-cols-4
   md:grid-cols-5
   md:grid-cols-6
   md:grid-cols-7
   md:grid-cols-8
   md:grid-cols-9
   md:grid-cols-10
   md:grid-cols-11
   md:grid-cols-12

   lg:grid-cols-1
   lg:grid-cols-2
   lg:grid-cols-3
   lg:grid-cols-4
   lg:grid-cols-5
   lg:grid-cols-6
   lg:grid-cols-7
   lg:grid-cols-8
   lg:grid-cols-9
   lg:grid-cols-10
   lg:grid-cols-11
   lg:grid-cols-12

   xl:grid-cols-1
   xl:grid-cols-2
   xl:grid-cols-3
   xl:grid-cols-4
   xl:grid-cols-5
   xl:grid-cols-6
   xl:grid-cols-7
   xl:grid-cols-8
   xl:grid-cols-9
   xl:grid-cols-10
   xl:grid-cols-11
   xl:grid-cols-12

   2xl:grid-cols-1
   2xl:grid-cols-2
   2xl:grid-cols-3
   2xl:grid-cols-4
   2xl:grid-cols-5
   2xl:grid-cols-6
   2xl:grid-cols-7
   2xl:grid-cols-8
   2xl:grid-cols-9
   2xl:grid-cols-10
   2xl:grid-cols-11

   The `gaps` attribute defines the gap size vertically and horizontally between item for each breakpoint.

   sm:gap-1
   sm:gap-2
   sm:gap-3
   sm:gap-4
   sm:gap-5
   sm:gap-6
   sm:gap-7
   sm:gap-8
   sm:gap-9
   sm:gap-10
   sm:gap-11
   sm:gap-12

   md:gap-1
   md:gap-2
   md:gap-3
   md:gap-4
   md:gap-5
   md:gap-6
   md:gap-7
   md:gap-8
   md:gap-9
   md:gap-10
   md:gap-11
   md:gap-12

   lg:gap-1
   lg:gap-2
   lg:gap-3
   lg:gap-4
   lg:gap-5
   lg:gap-6
   lg:gap-7
   lg:gap-8
   lg:gap-9
   lg:gap-10
   lg:gap-11
   lg:gap-12

   xl:gap-1
   xl:gap-2
   xl:gap-3
   xl:gap-4
   xl:gap-5
   xl:gap-6
   xl:gap-7
   xl:gap-8
   xl:gap-9
   xl:gap-10
   xl:gap-11
   xl:gap-12

   2xl:gap-1
   2xl:gap-2
   2xl:gap-3
   2xl:gap-4
   2xl:gap-5
   2xl:gap-6
   2xl:gap-7
   2xl:gap-8
   2xl:gap-9
   2xl:gap-10
   2xl:gap-11
   2xl:gap-12

   The `class` attribute allows passing additional classes.
  """
  def grid(%{variant: "col-2"} = assigns) do
    assigns = Map.delete(assigns, :variant)

    ~H"""
    <.grid columns={%{sm: 1, lg: 2}} {assigns} />
    """
  end

  def grid(assigns) do
    ~H"""
    <div class={[column_class(@columns), gap_class(@gaps), "grid", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :gaps, :any, default: %{"sm" => 4, "lg" => 6}
  attr :class, :any, default: nil
  attr :column, :boolean, default: false, required: false
  attr :rest, :global

  slot :inner_block

  def flex(assigns) do
    ~H"""
    <div class={[gap_class(@gaps), "flex", @class, @column && "flex-col"]} {@rest}>
      {render_slot(@inner_block)}
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
    break_points
    |> Enum.sort_by(fn {breakpoint, _} -> Enum.find_index(@breakpoints, fn b -> b == to_string(breakpoint) end) || 100 end)
    |> Enum.with_index()
    |> Enum.map(fn
      {{_breakpoint, num}, idx} when idx == 0 -> fun.(nil, num)
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
