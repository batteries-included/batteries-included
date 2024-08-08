defmodule ControlServerWeb.Live.TraditionalServicesIndex do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.TraditionalServicesTable

  alias ControlServer.TraditionalServices

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, "Traditional Services")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {services, meta}} <- TraditionalServices.list_traditional_services(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:services, services)
       |> assign(:form, to_form(meta))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("search", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/traditional_services?#{params}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/devtools"}>
      <.button variant="dark" icon={:plus} link={new_url()}>
        New Traditional Service
      </.button>
    </.page_header>

    <.panel title="All Services">
      <:menu>
        <.table_search
          meta={@meta}
          fields={[name: [op: :ilike]]}
          placeholder="Filter by name"
          on_change="search"
        />
      </:menu>

      <.traditional_services_table rows={@services} meta={@meta} />
    </.panel>
    """
  end

  defp new_url, do: "/traditional_services/new"
end
