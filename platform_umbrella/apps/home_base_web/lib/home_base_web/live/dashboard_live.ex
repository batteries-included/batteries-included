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
    <div class="flex items-center justify-center min-h-full">
      <div class="text-center">
        <.icon name={:chart_pie} class="size-60 m-auto text-primary opacity-15" />

        <p class="text-gray-light text-lg font-medium mb-12">
          Dashboard is coming soon.
        </p>
      </div>
    </div>
    """
  end
end
