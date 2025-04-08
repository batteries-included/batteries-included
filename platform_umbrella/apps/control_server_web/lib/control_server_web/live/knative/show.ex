defmodule ControlServerWeb.Live.KnativeShow do
  @moduledoc """
  LiveView to display all the most relevant status of a Knative Service.

  This depends on the Knative operator being installed and
  the owned resources being present in kubernetes.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ActionsDropdown
  import ControlServerWeb.Audit.EditVersionsTable
  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.Containers.EnvValuePanel
  import ControlServerWeb.DeploymentsTable
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ResourceComponents
  import KubeServices.SystemState.SummaryURLs

  alias CommonCore.Resources.OwnerReference
  alias ControlServer.Knative
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = KubeEventCenter.subscribe(:pod)
      :ok = KubeEventCenter.subscribe(:knative_service)
      :ok = KubeEventCenter.subscribe(:knative_revision)
    end

    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign_service(id)
     |> assign_main_k8s()
     |> assign_timeline_installed()
     |> maybe_assign_edit_versions()
     |> maybe_assign_k8_pods()
     |> maybe_assign_events()
     |> maybe_assign_k8_deployments()}
  end

  defp assign_timeline_installed(socket) do
    assign(socket, :timeline_installed, SummaryBatteries.battery_installed(:timeline))
  end

  defp assign_service(socket, id) do
    service = Knative.get_service!(id, preload: [:project])
    assign(socket, service: service, id: id)
  end

  defp assign_main_k8s(%{assigns: %{service: service}} = socket) do
    k8_service = k8_service(service)
    k8_configuration = k8_configuration(k8_service)

    socket
    |> assign(:k8_service, k8_service)
    |> assign(:k8_configuration, k8_configuration)
    |> assign(:k8_revisions, k8_revisions(k8_configuration))
  end

  defp maybe_assign_k8_pods(%{assigns: %{service: service, live_action: live_action}} = socket)
       when live_action == :pods do
    assign(socket, :k8_pods, k8_pods(service))
  end

  defp maybe_assign_k8_pods(socket), do: socket

  defp maybe_assign_k8_deployments(%{assigns: %{service: service, live_action: live_action}} = socket)
       when live_action == :deployments do
    assign(socket, :k8_deployments, k8_deployments(service))
  end

  defp maybe_assign_k8_deployments(socket), do: socket

  defp maybe_assign_edit_versions(%{assigns: %{service: service, live_action: live_action}} = socket)
       when live_action == :edit_versions do
    assign(socket, :edit_versions, ControlServer.Audit.history(service))
  end

  defp maybe_assign_edit_versions(socket), do: socket

  defp maybe_assign_events(%{assigns: %{live_action: live_action, k8_service: k8_service}} = socket)
       when live_action == :events do
    assign(socket, :events, KubeState.get_events(k8_service))
  end

  defp maybe_assign_events(socket), do: socket

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, socket |> assign_main_k8s() |> maybe_assign_k8_pods() |> maybe_assign_k8_deployments()}
  end

  def k8_service(service) do
    :knative_service
    |> KubeState.get_all()
    |> Enum.filter(fn s -> service.id == labeled_owner(s) end)
    |> Enum.at(0, %{})
  end

  def k8_configuration(k8_service) do
    :knative_configuration
    |> KubeState.get_all()
    |> Enum.filter(fn c -> uid(k8_service) == OwnerReference.get_owner(c) end)
    |> Enum.at(0, %{})
  end

  def k8_revisions(k8_configuration) do
    Enum.filter(
      KubeState.get_all(:knative_revision),
      fn r -> uid(k8_configuration) == OwnerReference.get_owner(r) end
    )
  end

  defp k8_pods(service) do
    :pod
    |> KubeState.get_all()
    |> Enum.filter(fn pod -> service.id == labeled_owner(pod) end)
  end

  defp k8_deployments(service) do
    :deployment
    |> KubeState.get_all()
    |> Enum.filter(fn deployment -> service.id == labeled_owner(deployment) end)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = Knative.delete_service(socket.assigns.service)

    {:noreply, push_navigate(socket, to: ~p"/knative/services")}
  end

  defp page_title(:show), do: "Knative Service"
  defp page_title(:edit_versions), do: "Knative Service: Edit History"
  defp page_title(:pods), do: "Knative Service: Pods"
  defp page_title(:deployments), do: "Knative Service: Deployments"
  defp page_title(:events), do: "Knative Service: Events"

  defp edit_url(service), do: ~p"/knative/services/#{service}/edit"
  defp show_url(service), do: ~p"/knative/services/#{service}/show"

  defp edit_versions_url(service), do: ~p"/knative/services/#{service}/edit_versions"
  defp events_url(service), do: ~p"/knative/services/#{service}/events"
  defp pods_url(service), do: ~p"/knative/services/#{service}/pods"
  defp deployments_url(service), do: ~p"/knative/services/#{service}/deployments"

  defp service_url(service), do: knative_service_url(service)

  defp traffic(service) do
    get_in(service, ~w(status traffic)) || []
  end

  defp actual_replicas(revision) do
    get_in(revision, ~w(status actualReplicas)) || 0
  end

  defp traffic_chart_data(traffic_list) do
    dataset = %{
      data: Enum.map(traffic_list, &get_in(&1, ~w(percent))),
      label: "Traffic"
    }

    labels = Enum.map(traffic_list, &get_in(&1, ~w(revisionName)))

    %{labels: labels, datasets: [dataset]}
  end

  defp header(assigns) do
    ~H"""
    <.page_header title={"Knative Service: #{@service.name}"} back_link={@back_link}>
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

  defp traffic_display(assigns) do
    ~H"""
    <.panel title="Traffic Split" class={@class}>
      <.grid columns={[sm: 1, lg: 2]} class="items-center">
        <.table rows={@traffic} id="traffic-table">
          <:col :let={split} label="Revision">{Map.get(split, "revisionName", "")}</:col>
          <:col :let={split} label="Percent">{Map.get(split, "percent", 0)}</:col>
        </.table>
        <.chart class="max-h-[32rem] mx-auto" id="traffic-chart" data={traffic_chart_data(@traffic)} />
      </.grid>
    </.panel>
    """
  end

  def revisions_display(assigns) do
    ~H"""
    <.panel title="Revisions" class={@class}>
      <.table rows={@revisions} id="revisions-table">
        <:col :let={rev} label="Name">{name(rev)}</:col>
        <:col :let={rev} label="Replicas">{actual_replicas(rev)}</:col>
        <:col :let={rev} label="Created">{creation_timestamp(rev)}</:col>
      </.table>
    </.panel>
    """
  end

  defp main_page(assigns) do
    ~H"""
    <.header service={@service} back_link={~p"/knative/services"} />

    <.grid columns={%{sm: 1, lg: 4}}>
      <.panel title="Details" class="lg:col-span-3 lg:row-span-2">
        <.data_list>
          <:item title="Rollout Duration">
            {@service.rollout_duration}
          </:item>
          <:item title="Namespace">
            {namespace(@k8_service)}
          </:item>
          <:item title="Started">
            <.relative_display time={creation_timestamp(@k8_service)} />
          </:item>
        </.data_list>
      </.panel>

      <.links_panel
        service={@service}
        live_action={@live_action}
        timeline_installed={@timeline_installed}
      />

      <.traffic_display
        :if={length(traffic(@k8_service)) > 1}
        traffic={traffic(@k8_service)}
        class="lg:col-span-4"
      />
      <.revisions_display revisions={@k8_revisions} class="lg:col-span-2" variant="gray" />
      <.env_var_panel
        env_values={@service.env_values}
        class="lg:col-span-2"
        editable={false}
        variant="gray"
      />
      <.conditions_display
        conditions={conditions(@k8_service)}
        class="lg:col-span-4"
        variant="default"
      />
    </.grid>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.header
      service={@service}
      timeline_installed={@timeline_installed}
      back_link={show_url(@service)}
    />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
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

  defp pods_page(assigns) do
    ~H"""
    <.header
      service={@service}
      timeline_installed={@timeline_installed}
      back_link={show_url(@service)}
    />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
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

  defp deployments_page(assigns) do
    ~H"""
    <.header
      service={@service}
      timeline_installed={@timeline_installed}
      back_link={show_url(@service)}
    />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.panel title="Deployments" class="lg:col-span-3 lg:row-span-2">
        <.deployments_table deployments={@k8_deployments} />
      </.panel>

      <.links_panel
        service={@service}
        live_action={@live_action}
        timeline_installed={@timeline_installed}
      />
    </.grid>
    """
  end

  defp events_page(assigns) do
    ~H"""
    <.header
      service={@service}
      timeline_installed={@timeline_installed}
      back_link={show_url(@service)}
    />

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

  defp links_panel(assigns) do
    ~H"""
    <.panel variant="gray">
      <.tab_bar variant="navigation">
        <:tab selected={@live_action == :show} patch={show_url(@service)}>Overview</:tab>
        <:tab selected={@live_action == :pods} patch={pods_url(@service)}>Pods</:tab>
        <:tab selected={@live_action == :deployments} patch={deployments_url(@service)}>
          Deployments
        </:tab>
        <:tab selected={@live_action == :events} patch={events_url(@service)}>Events</:tab>
        <:tab
          :if={@timeline_installed}
          selected={@live_action == :edit_versions}
          patch={edit_versions_url(@service)}
        >
          Edit Versions
        </:tab>
      </.tab_bar>
      <.a
        :if={!@service.kube_internal}
        variant="bordered"
        href={service_url(@service)}
        class="mt-4 hover:shadow-lg"
      >
        Running Service
      </.a>
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :show -> %>
        <.main_page
          live_action={@live_action}
          k8_service={@k8_service}
          service={@service}
          k8_revisions={@k8_revisions}
          page_title={@page_title}
          timeline_installed={@timeline_installed}
        />
      <% :edit_versions -> %>
        <.edit_versions_page
          live_action={@live_action}
          service={@service}
          edit_versions={@edit_versions}
          timeline_installed={@timeline_installed}
        />
      <% :pods -> %>
        <.pods_page
          live_action={@live_action}
          service={@service}
          k8_pods={@k8_pods}
          timeline_installed={@timeline_installed}
        />
      <% :deployments -> %>
        <.deployments_page
          live_action={@live_action}
          service={@service}
          timeline_installed={@timeline_installed}
          k8_deployments={@k8_deployments}
        />
      <% :events -> %>
        <.events_page
          live_action={@live_action}
          service={@service}
          events={@events}
          timeline_installed={@timeline_installed}
        />
    <% end %>
    """
  end
end
