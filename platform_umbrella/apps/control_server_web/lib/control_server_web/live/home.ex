defmodule ControlServerWeb.Live.Home do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  def render(assigns) do
    ~H"""
    <.layout>Coming Soon</.layout>
    """
  end
end
