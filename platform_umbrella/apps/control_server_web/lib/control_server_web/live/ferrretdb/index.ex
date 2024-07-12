defmodule ControlServerWeb.Live.FerretServiceIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.FerretServicesTable

  alias ControlServer.FerretDB

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :data)
     |> assign(:ferret_services, FerretDB.list_ferret_services())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Listing FerretDB services")
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/data"}>
      <.button variant="secondary" link={~p"/ferretdb/new"}>
        New FerretDB
      </.button>
    </.page_header>
    <.panel title="All FerretDB/MongoDB Services">
      <.ferret_services_table rows={@ferret_services} />
    </.panel>
    """
  end
end
