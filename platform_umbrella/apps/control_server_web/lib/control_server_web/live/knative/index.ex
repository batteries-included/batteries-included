defmodule ControlServerWeb.Live.KnativeServicesIndex do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import KubeResources.KnativeServing, only: [url: 1]

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
          <.link href={url(service)} type="external">
            <%= url(service) %>
          </.link>
        </:col>
        <:action :let={service}>
          <.link navigate={show_url(service)}>Show Service</.link>
        </:action>
      </.table>

      <.h2>Actions</.h2>
      <.body_section>
        <.link navigate={service_new_url()}>
          <.button>
            New Knative Service
          </.button>
        </.link>
      </.body_section>
    </.layout>
    """
  end

  defp show_url(%Knative.Service{} = service),
    do: Routes.knative_show_path(ControlServerWeb.Endpoint, :show, service.id)

  defp service_new_url do
    Routes.knative_new_path(ControlServerWeb.Endpoint, :new)
  end
end
