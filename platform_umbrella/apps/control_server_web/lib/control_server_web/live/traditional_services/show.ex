defmodule ControlServerWeb.Live.TraditionalServicesShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ActionsDropdown
  import ControlServerWeb.Audit.EditVersionsTable
  import ControlServerWeb.Containers.EnvValuePanel
  import ControlServerWeb.PodsTable
  import ControlServerWeb.PortPanel
  import ControlServerWeb.ResourceComponents
  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.TraditionalServices.Service
  alias CommonCore.Util.Memory
  alias ControlServer.TraditionalServices
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries

  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, "Traditional Service")
     |> assign_all(id)}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign_all(socket, id)}
  end

  defp assign_all(socket, id) do
    socket
    |> assign_service(id)
    |> assign_k8_resource()
    |> assign_timeline_installed()
    |> maybe_assign_events()
    |> maybe_assign_k8_pods()
    |> maybe_assign_edit_versions()
  end

  defp assign_service(socket, id) do
    assign(socket, :service, TraditionalServices.get_service!(id, preload: [:project]))
  end

  defp assign_k8_resource(%{assigns: %{service: %{kube_deployment_type: :statefulset, id: id}}} = socket) do
    assign(socket, :k8_resource, find_k8_resource(id, :stateful_set))
  end

  defp assign_k8_resource(%{assigns: %{service: %{kube_deployment_type: :deployment, id: id}}} = socket) do
    assign(socket, :k8_resource, find_k8_resource(id, :deployment))
  end

  defp maybe_assign_events(%{assigns: %{live_action: live_action, k8_resource: k8_resource}} = socket)
       when live_action == :events do
    assign(socket, :events, KubeState.get_events(k8_resource))
  end

  defp maybe_assign_events(socket), do: socket

  defp maybe_assign_k8_pods(%{assigns: %{live_action: live_action, service: service}} = socket)
       when live_action == :pods do
    assign(socket, :k8_pods, find_k8_pods(service.id))
  end

  defp maybe_assign_k8_pods(socket), do: socket

  defp maybe_assign_edit_versions(%{assigns: %{service: service, live_action: live_action}} = socket)
       when live_action == :edit_versions do
    assign(socket, :edit_versions, ControlServer.Audit.history(service))
  end

  defp maybe_assign_edit_versions(socket), do: socket

  defp assign_timeline_installed(socket) do
    assign(socket, :timeline_installed, SummaryBatteries.battery_installed(:timeline))
  end

  defp find_k8_resource(id, type) do
    type
    |> KubeState.get_all()
    |> Enum.find(nil, fn pg -> id == labeled_owner(pg) end)
  end

  defp find_k8_pods(id) do
    :pod
    |> KubeState.get_all()
    |> Enum.filter(fn pg -> id == labeled_owner(pg) end)
  end

  def handle_event("delete", _params, socket) do
    {:ok, _} = TraditionalServices.delete_service(socket.assigns.service)

    {:noreply,
     socket
     |> put_flash(:global_success, "Service successfully deleted")
     |> push_navigate(to: ~p"/traditional_services")}
  end

  defp traditional_service_page_header(assigns) do
    ~H"""
    <.page_header title={"Traditional Service: #{@service.name}"} back_link={@back_url}>
      <:menu>
        <.badge :if={@service.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@service.project_id}/show"}>
            {@service.project.name}
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.actions_dropdown>
          <.dropdown_link navigate={edit_url(@service)} icon={:pencil}>
            Edit Service
          </.dropdown_link>

          <.dropdown_button
            class="w-full"
            icon={:trash}
            phx-click="delete"
            data-confirm={"Are you sure you want to delete the #{@service.name} model?"}
          >
            Delete Service
          </.dropdown_button>
        </.actions_dropdown>
      </.flex>
    </.page_header>
    """
  end

  defp links_panel(assigns) do
    ~H"""
    <.panel variant="gray">
      <.tab_bar variant="navigation">
        <:tab selected={@live_action == :show} patch={show_url(@service)}>Overview</:tab>
        <:tab selected={@live_action == :events} patch={events_url(@service)}>Events</:tab>
        <:tab selected={@live_action == :pods} patch={pods_url(@service)}>Pods</:tab>
        <:tab
          :if={@timeline_installed}
          selected={@live_action == :edit_versions}
          patch={edit_versions_url(@service)}
        >
          Edit Versions
        </:tab>
      </.tab_bar>
      <.a variant="bordered" href={service_url(@service)} class="mt-4 hover:shadow-lg">
        Running Service
      </.a>
    </.panel>
    """
  end

  defp events_page(assigns) do
    ~H"""
    <.traditional_service_page_header service={@service} back_url={show_url(@service)} />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-3">
      <.events_panel class="lg:col-span-3  lg:row-span-2" events={@events} />
      <.links_panel
        service={@service}
        live_action={@live_action}
        timeline_installed={@timeline_installed}
      />
    </.grid>
    """
  end

  defp pods_page(assigns) do
    ~H"""
    <.traditional_service_page_header service={@service} back_url={show_url(@service)} />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-3">
      <.panel title="Pods" class="lg:col-span-3 lg:row-span-2">
        <.pods_table pods={@k8_pods} />
      </.panel>
      <.links_panel
        service={@service}
        live_action={@live_action}
        timeline_installed={@timeline_installed}
      />
    </.grid>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.traditional_service_page_header service={@service} back_url={show_url(@service)} />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-3">
      <.panel title="Edit History" class="lg:col-span-3 lg:row-span-2">
        <.edit_versions_table rows={@edit_versions} abridged />
      </.panel>
      <.links_panel
        service={@service}
        timeline_installed={@timeline_installed}
        live_action={@live_action}
      />
    </.grid>
    """
  end

  defp main_page(assigns) do
    ~H"""
    <.traditional_service_page_header service={@service} back_url={~p"/traditional_services"} />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-4">
      <.panel title="Details" class="lg:col-span-3 lg:row-span-2">
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
      <.links_panel
        service={@service}
        live_action={@live_action}
        timeline_installed={@timeline_installed}
      />
      <.env_var_panel
        :if={!Enum.empty?(@service.env_values || [])}
        env_values={@service.env_values || []}
        class="lg:col-span-4"
        variant="gray"
      />
      <.port_panel
        :if={!Enum.empty?(@service.ports || [])}
        ports={@service.ports || []}
        class="lg:col-span-4"
      />
    </.grid>
    """
  end

  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :show -> %>
        <.main_page
          live_action={@live_action}
          service={@service}
          timeline_installed={@timeline_installed}
        />
      <% :events -> %>
        <.events_page
          live_action={@live_action}
          service={@service}
          events={@events}
          timeline_installed={@timeline_installed}
        />
      <% :pods -> %>
        <.pods_page
          live_action={@live_action}
          service={@service}
          k8_pods={@k8_pods}
          timeline_installed={@timeline_installed}
        />
      <% :edit_versions -> %>
        <.edit_versions_page
          live_action={@live_action}
          service={@service}
          edit_versions={@edit_versions}
          timeline_installed={@timeline_installed}
        />
    <% end %>
    """
  end

  defp show_url(service), do: ~p"/traditional_services/#{service}/show"
  defp events_url(service), do: ~p"/traditional_services/#{service}/events"
  defp pods_url(service), do: ~p"/traditional_services/#{service}/pods"
  defp edit_url(service), do: ~p"/traditional_services/#{service}/edit"
  defp edit_versions_url(service), do: ~p"/traditional_services/#{service}/edit_versions"
  defp service_url(%Service{} = service), do: "//#{traditional_host(service)}"
end
