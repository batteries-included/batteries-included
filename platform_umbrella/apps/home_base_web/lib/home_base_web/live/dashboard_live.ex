defmodule HomeBaseWeb.DashboardLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page, :dashboard)
     |> assign(:page_title, "Dashboard")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    Coming Soon
    """
  end
end
