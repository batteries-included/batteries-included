defmodule ControlServerWeb.Live.BackendShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Backend.Service
  alias CommonCore.Util.Memory
  alias ControlServer.Backend

  def mount(%{"id" => id}, _session, socket) do
    service = Backend.get_service!(id, preload: [:project])

    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, "Backend Service")
     |> assign(:service, service)}
  end

  def handle_event("delete", _params, socket) do
    {:ok, _} = Backend.delete_service(socket.assigns.service)

    {:noreply,
     socket
     |> put_flash(:global_success, "Backend successfully deleted")
     |> push_navigate(to: ~p"/backend/services")}
  end

  def render(assigns) do
    ~H"""
    <.page_header title={"Backend Service: #{@service.name}"} back_link={back_url()}>
      <:menu>
        <.badge :if={@service.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@service.project_id}"}>
            <%= @service.project.name %>
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.tooltip target_id="edit-tooltip">Edit Service</.tooltip>
        <.tooltip target_id="delete-tooltip">Delete Service</.tooltip>
        <.flex gaps="0">
          <.button id="edit-tooltip" variant="icon" icon={:pencil} link={edit_url(@service)} />
          <.button
            id="delete-tooltip"
            variant="icon"
            icon={:trash}
            phx-click="delete"
            data-confirm="Are you sure?"
          />
        </.flex>
      </.flex>
    </.page_header>

    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="Details" variant="gray">
        <.data_list>
          <:item title="Instances">
            <%= @service.num_instances %>
          </:item>
          <:item :if={@service.memory_limits} title="Memory limits">
            <%= Memory.humanize(@service.memory_limits) %>
          </:item>
          <:item title="Deployment Type">
            <%= @service.kube_deployment_type %>
          </:item>
          <:item title="Started">
            <.relative_display time={@service.inserted_at} />
          </:item>
        </.data_list>
      </.panel>

      <.flex column class="justify-start">
        <.a variant="bordered" href={service_url(@service)}>Running Service</.a>
      </.flex>
    </.grid>
    """
  end

  defp back_url, do: ~p"/backend/services"
  defp edit_url(service), do: ~p"/backend/services/#{service}/edit"
  defp service_url(%Service{} = service), do: "//#{backend_host(service)}"
end
