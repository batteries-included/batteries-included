defmodule ControlServerWeb.Live.Home do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      Intentionally Empty
    </.layout>
    """
  end
end
