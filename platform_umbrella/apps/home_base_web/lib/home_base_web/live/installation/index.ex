defmodule HomeBaseWeb.Live.Installations do
  use HomeBaseWeb, :live_view

  import HomeBaseWeb.TopMenuLayout

  alias HomeBase.ControlServerClusters

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :installations, list_installations())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Listing Installations")
  end

  defp list_installations do
    ControlServerClusters.list_installations()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.top_menu_layout page={:installations} title={@page_title}>
      <.a navigate={~p"/installations/new"}>
        <.button>New Installation</.button>
      </.a>
      <.table
        id="installations"
        rows={@installations}
        row_click={&JS.navigate(~p"/installations/#{&1}/show")}
      >
        <:col :let={installation} label="Id"><%= installation.id %></:col>
        <:col :let={installation} label="Slug"><%= installation.slug %></:col>
        <:action :let={installation}>
          <div class="sr-only">
            <.a navigate={~p"/installations/#{installation}/show"}>Show</.a>
          </div>
          <.a navigate={~p"/installations/#{installation}/show"}>Edit</.a>
        </:action>
      </.table>
    </.top_menu_layout>
    """
  end
end
