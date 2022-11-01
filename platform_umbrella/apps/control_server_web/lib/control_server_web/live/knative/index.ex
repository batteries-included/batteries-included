defmodule ControlServerWeb.Live.KnativeServicesIndex do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  alias KubeResources.KnativeServing, as: KnativeResources

  alias ControlServer.Knative

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :services, list_services())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Listing Services")
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    service = Knative.get_service!(id)
    {:ok, _} = Knative.delete_service(service)

    {:noreply, assign(socket, :services, list_services())}
  end

  defp list_services do
    Knative.list_services()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout group={:devtools} active={:knative_serving}>
      <:title>
        <.title>Knative Services</.title>
      </:title>
      <.section_title>
        Knative Services
      </.section_title>
      <.table id="knative-display-table" rows={@services}>
        <:col :let={service} label="Name"><%= service.name %></:col>
        <:col :let={service} label="Link">
          <.link href={service_url(service)} type="external">
            <%= service_url(service) %>
          </.link>
        </:col>
        <:action :let={service}>
          <.link navigate={~p"/knative/services/#{service}/show"}>Show Service</.link>
        </:action>
      </.table>

      <.h2>Actions</.h2>
      <.body_section>
        <.link navigate={~p"/knative/services/new"}>
          <.button>
            New Knative Service
          </.button>
        </.link>
      </.body_section>
    </.layout>
    """
  end

  defp service_url(%Knative.Service{} = service), do: KnativeResources.url(service)
end
