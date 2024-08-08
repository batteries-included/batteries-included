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
     |> assign(:page_title, "Listing FerretDB services")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {ferret_services, meta}} <- FerretDB.list_ferret_services(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:ferret_services, ferret_services)
       |> assign(:form, to_form(meta))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("search", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/ferretdb?#{params}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/data"}>
      <.button variant="dark" icon={:plus} link={~p"/ferretdb/new"}>
        New FerretDB Service
      </.button>
    </.page_header>

    <.panel title="All FerretDB/MongoDB Services">
      <:menu>
        <.table_search
          meta={@meta}
          fields={[name: [op: :ilike]]}
          placeholder="Filter by name"
          on_change="search"
        />
      </:menu>

      <.ferret_services_table rows={@ferret_services} meta={@meta} />
    </.panel>
    """
  end
end
