defmodule ControlServerWeb.Live.KnativeShow do
  @moduledoc """
  LiveView to display all the most relevant status of a Knative Service.

  This depends on the Knative operator being installed and
  the owned resources being present in kubernetes.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.Audit.EditVersionsTable
  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.Containers.EnvValuePanel
  import ControlServerWeb.PodsTable
  import KubeServices.SystemState.SummaryURLs

  alias CommonCore.Resources.OwnerReference
  alias ControlServer.Knative
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = KubeEventCenter.subscribe(:pod)
    :ok = KubeEventCenter.subscribe(:knative_service)
    :ok = KubeEventCenter.subscribe(:knative_revision)

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
     |> assign_k8s()
     |> assign_timeline_installed()
     |> maybe_assign_edit_versions()}
  end

  defp assign_timeline_installed(socket) do
    assign(socket, :timeline_installed, SummaryBatteries.battery_installed(:timeline))
  end

  defp assign_service(socket, id) do
    service = Knative.get_service!(id, preload: [:project])
    assign(socket, service: service, id: id)
  end

  defp assign_k8s(%{assigns: %{service: service}} = socket) do
    k8_service = k8_service(service)
    k8_configuration = k8_configuration(k8_service)
    k8_pods = k8_pods(service)

    socket
    |> assign(:k8_pods, k8_pods)
    |> assign(:k8_service, k8_service)
    |> assign(:k8_configuration, k8_configuration)
    |> assign(:k8_revisions, k8_revisions(k8_configuration))
  end

  defp maybe_assign_edit_versions(%{assigns: %{service: service, live_action: live_action}} = socket)
       when live_action == :edit_versions do
    assign(socket, :edit_versions, ControlServer.Audit.history(service))
  end

  defp maybe_assign_edit_versions(socket), do: socket

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, assign_k8s(socket)}
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

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = Knative.delete_service(socket.assigns.service)

    {:noreply, push_navigate(socket, to: ~p"/knative/services")}
  end

  defp page_title(:show), do: "Knative Service"
  defp page_title(:edit_versions), do: "Knative Service: Edit History"
  defp page_title(:env_vars), do: "Knative Service: Environment Variables"

  defp edit_url(service), do: ~p"/knative/services/#{service}/edit"
  defp show_url(service), do: ~p"/knative/services/#{service}/show"
  defp env_vars_url(service), do: ~p"/knative/services/#{service}/env_vars"

  defp edit_versions_url(service), do: ~p"/knative/services/#{service}/edit_versions"
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
    <.page_header title={"Knative Service: #{@service.name}"} back_link={~p"/knative/services"}>
      <:menu>
        <.badge :if={@service.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@service.project_id}"}>
            <%= @service.project.name %>
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.tooltip :if={@timeline_installed} target_id="history-tooltip">Edit History</.tooltip>
        <.tooltip target_id="edit-tooltip">Edit Service</.tooltip>
        <.tooltip target_id="delete-tooltip">Delete Service</.tooltip>
        <.flex gaps="0">
          <.button
            :if={@timeline_installed}
            id="history-tooltip"
            variant="icon"
            icon={:clock}
            link={edit_versions_url(@service)}
          />
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
    """
  end

  defp traffic_display(assigns) do
    ~H"""
    <.panel title="Traffic Split" class="lg:col-span-2">
      <.grid columns={[sm: 1, lg: 2]} class="items-center">
        <.table rows={@traffic} id="traffic-table">
          <:col :let={split} label="Revision"><%= Map.get(split, "revisionName", "") %></:col>
          <:col :let={split} label="Percent"><%= Map.get(split, "percent", 0) %></:col>
        </.table>
        <.chart class="max-h-[32rem] mx-auto" id="traffic-chart" data={traffic_chart_data(@traffic)} />
      </.grid>
    </.panel>
    """
  end

  def revisions_display(assigns) do
    ~H"""
    <.panel title="Revisions">
      <.table rows={@revisions} id="revisions-table">
        <:col :let={rev} label="Name"><%= name(rev) %></:col>
        <:col :let={rev} label="Replicas"><%= actual_replicas(rev) %></:col>
        <:col :let={rev} label="Created"><%= creation_timestamp(rev) %></:col>
      </.table>
    </.panel>
    """
  end

  defp main_page(assigns) do
    ~H"""
    <.header service={@service} timeline_installed={@timeline_installed} />

    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="Details" variant="gray">
        <.data_list>
          <:item title="Rollout Duration">
            <%= @service.rollout_duration %>
          </:item>
          <:item title="Namespace">
            <%= namespace(@k8_service) %>
          </:item>
          <:item title="Started">
            <.relative_display time={creation_timestamp(@k8_service)} />
          </:item>
        </.data_list>
      </.panel>

      <.flex column class="justify-start">
        <.a variant="bordered" navigate={env_vars_url(@service)}>Env Variables</.a>
        <.a variant="bordered" href={service_url(@service)}>Running Service</.a>
      </.flex>

      <.traffic_display :if={length(traffic(@k8_service)) > 1} traffic={traffic(@k8_service)} />
      <.revisions_display revisions={@k8_revisions} />
      <.conditions_display conditions={conditions(@k8_service)} />
      <.panel title="Pods" class="col-span-2">
        <.pods_table pods={@k8_pods} />
      </.panel>
    </.grid>
    """
  end

  defp environment_variables_page(assigns) do
    ~H"""
    <.header service={@service} timeline_installed={@timeline_installed} />

    <.grid columns={%{sm: 1, lg: 2}}>
      <.env_var_panel env_values={@service.env_values} />
      <.flex column class="justify-start">
        <.a variant="bordered" navigate={show_url(@service)}>Show Service</.a>
        <.a variant="bordered" href={service_url(@service)}>Running Service</.a>
      </.flex>
    </.grid>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.header service={@service} timeline_installed={@timeline_installed} />

    <.panel title="Edit History">
      <.edit_versions_table rows={@edit_versions} abridged />
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :show -> %>
        <.main_page
          k8_service={@k8_service}
          service={@service}
          k8_revisions={@k8_revisions}
          page_title={@page_title}
          timeline_installed={@timeline_installed}
          k8_pods={@k8_pods}
        />
      <% :env_vars -> %>
        <.environment_variables_page
          k8_service={@k8_service}
          service={@service}
          k8_revisions={@k8_revisions}
          page_title={@page_title}
          timeline_installed={@timeline_installed}
        />
      <% :edit_versions -> %>
        <.edit_versions_page
          service={@service}
          edit_versions={@edit_versions}
          timeline_installed={@timeline_installed}
        />
    <% end %>
    """
  end
end
