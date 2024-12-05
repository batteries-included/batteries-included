defmodule ControlServerWeb.Live.TraditionalServicesShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Containers.EnvValuePanel
  import ControlServerWeb.PortPanel
  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.TraditionalServices.Service
  alias CommonCore.Util.Memory
  alias ControlServer.TraditionalServices

  def mount(%{"id" => id}, _session, socket) do
    service = TraditionalServices.get_service!(id, preload: [:project])

    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, "Traditional Service")
     |> assign(:service, service)}
  end

  def handle_event("delete", _params, socket) do
    {:ok, _} = TraditionalServices.delete_service(socket.assigns.service)

    {:noreply,
     socket
     |> put_flash(:global_success, "Service successfully deleted")
     |> push_navigate(to: ~p"/traditional_services")}
  end

  def render(assigns) do
    ~H"""
    <.page_header title={"Traditional Service: #{@service.name}"} back_link={back_url()}>
      <:menu>
        <.badge :if={@service.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@service.project_id}"}>
            {@service.project.name}
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
            {@service.num_instances}
          </:item>
          <:item :if={@service.memory_limits} title="Memory limits">
            {Memory.humanize(@service.memory_limits)}
          </:item>
          <:item title="Deployment Type">
            {@service.kube_deployment_type}
          </:item>
          <:item title="Started">
            <.relative_display time={@service.inserted_at} />
          </:item>
        </.data_list>
      </.panel>

      <.flex column class="justify-start">
        <.a variant="bordered" href={service_url(@service)}>Running Service</.a>
      </.flex>

      <.env_var_panel env_values={@service.env_values} class="lg:col-span-1" />
      <.port_panel ports={@service.ports} class="lg:col-span-1" />
    </.grid>
    """
  end

  defp back_url, do: ~p"/traditional_services"
  defp edit_url(service), do: ~p"/traditional_services/#{service}/edit"
  defp service_url(%Service{} = service), do: "//#{traditional_host(service)}"
end
