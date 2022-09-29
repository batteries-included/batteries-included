defmodule ControlServerWeb.Live.KnativeServicesIndex do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import KubeResources.KnativeServing, only: [url: 1]

  alias ControlServer.Knative
  alias ControlServer.Services.RunnableService
  alias ControlServer.Services, as: ControlServices

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :services, list_services())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, socket |> apply_action(socket.assigns.live_action, params) |> assign_services()}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Services")
    |> assign(:service, nil)
  end

  def assign_services(socket) do
    runnable_services = RunnableService.prefix("/devtools")
    service_types = Enum.map(runnable_services, fn rs -> rs.service_type end)
    base_services = ControlServices.from_service_types(service_types)

    assign(socket, :base_services, base_services)
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
    <.layout>
      <:title>
        <.title>Knative Services</.title>
      </:title>
      <:left_menu>
        <.devtools_menu active="knative" base_services={@base_services} />
      </:left_menu>
      <.section_title>
        Knative Services
      </.section_title>
      <.body_section>
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

        <div class="ml-8 mt-15">
          <.link navigate={service_new_url()}>
            <.button type="primary">
              New Knative Service
            </.button>
          </.link>
        </div>
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
