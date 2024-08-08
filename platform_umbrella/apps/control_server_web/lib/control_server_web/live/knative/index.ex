defmodule ControlServerWeb.Live.KnativeIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.KnativeServicesTable

  alias ControlServer.Knative

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, "Knative Services")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {services, meta}} <- Knative.list_services(params) do
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
    {:noreply, push_patch(socket, to: ~p"/knative/services?#{params}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/devtools"}>
      <.button variant="dark" icon={:plus} link={new_url()}>
        New Knative Service
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

      <.knative_services_table rows={@services} meta={@meta} />
    </.panel>
    """
  end

  defp new_url, do: ~p"/knative/services/new"
end
