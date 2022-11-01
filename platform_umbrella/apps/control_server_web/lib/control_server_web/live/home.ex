defmodule ControlServerWeb.Live.Home do
  use ControlServerWeb, :live_view

  import ControlServerWeb.MenuLayout

  @impl true
  def render(assigns) do
    ~H"""
    <.menu_layout>
      Intentionally Empty
    </.menu_layout>
    """
  end
end
