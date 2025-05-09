defmodule ControlServerWeb.Projects.ExportToggleButton do
  @moduledoc false
  use ControlServerWeb, :html

  def export_toggle_button(assigns) do
    loc = Map.get(assigns, :location)

    phx_loc =
      loc
      |> Enum.with_index()
      |> Enum.map(fn {loc, i} -> {"phx-value-loc-#{i}", to_string(loc)} end)

    icon = if has_removal?(assigns[:removals], loc), do: :archive_box, else: :archive_box_x_mark

    assigns =
      assigns
      |> Map.put(:phx_value_loc, phx_loc)
      |> Map.put(:icon, icon)

    ~H"""
    <.button phx-click="toggle_remove" {@phx_value_loc} icon={@icon}>
      Toggle Export
    </.button>
    """
  end

  def location_from_params(params) do
    params
    |> Enum.filter(fn {key, _value} ->
      String.starts_with?(key, "loc-")
    end)
    |> Enum.map(fn {key, value} ->
      new_key = key |> String.replace("loc-", "") |> String.to_integer()
      {new_key, value}
    end)
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map(fn {_key, value} ->
      case Integer.parse(value) do
        {int, _} -> int
        _ -> String.to_existing_atom(value)
      end
    end)
  end

  defp has_removal?(removals, loc) do
    Enum.any?(removals, fn removal ->
      removal == loc
    end)
  end
end
