defmodule HomeBaseWeb.Live.Home do
  @moduledoc false
  use HomeBaseWeb, :live_view

  import HomeBaseWeb.TopMenuLayout

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.top_menu_layout title="Dashboard" page={:home}></.top_menu_layout>
    """
  end
end
