defmodule ControlServerWeb.Live.KnativeShow do
  @moduledoc """
  LiveView to display all the most relevant status of a Knative Service.

  This depends on the Knative operator being installed and
  the owned resources being present in kubernetes.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.Audit.EditVersionsTable
  import ControlServerWeb.Chart
  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.Containers.EnvValuePanel

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
    {:ok, assign(socket, :page_title, page_title(socket.assigns.live_action))}
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
    service = Knative.get_service!(id)
    assign(socket, service: service, id: id)
  end

  defp assign_k8s(%{assigns: %{service: service}} = socket) do
    k8_service = k8_service(service)
    k8_configuration = k8_configuration(k8_service)

    socket
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

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = Knative.delete_service(socket.assigns.service)

    {:noreply, push_navigate(socket, to: ~p"/knative/services")}
  end

  defp page_title(:show), do: "Show Knative Service"
  defp page_title(:edit_versions), do: "Knative Service: Edit History"

  defp edit_url(service), do: ~p"/knative/services/#{service}/edit"
  defp show_url(service), do: ~p"/knative/services/#{service}/show"
  defp edit_versions_url(service), do: ~p"/knative/services/#{service}/edit_versions"

  defp service_url(service) do
    get_in(service, ~w(status url))
  end

  defp traffic(service) do
    get_in(service, ~w(status traffic)) || []
  end

  defp actual_replicas(revision) do
    get_in(revision, ~w(status actualReplicas)) || 0
  end

  def service_display(assigns) do
    ~H"""
    <.traffic_display :if={length(traffic(@service)) > 1} traffic={traffic(@service)} />

    <.grid columns={[sm: 1, lg: 2]}>
      <.conditions_display conditions={conditions(@service)} />
      <.revisions_display revisions={@revisions} />
    </.grid>
    """
  end

  defp traffic_chart_data(traffic_list) do
    dataset = %{
      data: Enum.map(traffic_list, &get_in(&1, ~w(percent))),
      label: "Traffic"
    }

    labels = Enum.map(traffic_list, &get_in(&1, ~w(revisionName)))

    %{labels: labels, datasets: [dataset]}
  end

  defp traffic_display(assigns) do
    ~H"""
    <.panel title="Traffic Split">
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
    <.page_header title={@page_title} back_link={~p"/knative/services"}>
      <.flex>
        <.tooltip :if={@timeline_installed} target_id="history-tooltip">Edit History</.tooltip>
        <.flex gaps="0">
          <.button
            :if={@timeline_installed}
            id="history-tooltip"
            variant="icon"
            icon={:clock}
            link={edit_versions_url(@service)}
          />
          <.button variant="icon" icon={:pencil} link={edit_url(@service)} />
          <.button variant="icon" icon={:trash} phx-click="delete" data-confirm="Are you sure?" />
        </.flex>
      </.flex>
    </.page_header>

    <.flex column>
      <.badge>
        <:item label="Name"><%= @service.name %></:item>
        <:item label="Namespace"><%= namespace(@k8_service) %></:item>
        <:item label="Started">
          <.relative_display time={creation_timestamp(@k8_service)} />
        </:item>
        <:item label="URL">
          <.a href={service_url(@k8_service)} variant="external">
            <%= service_url(@k8_service) %>
          </.a>
        </:item>
      </.badge>

      <.service_display service={@k8_service} revisions={@k8_revisions} />
      <.env_var_panel env_values={@service.env_values} />
    </.flex>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.page_header title="Edit History" back_link={show_url(@service)} />
    <.panel title="Edit History">
      <.edit_versions_table edit_versions={@edit_versions} abbridged />
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
        />
      <% :edit_versions -> %>
        <.edit_versions_page service={@service} edit_versions={@edit_versions} />
    <% end %>
    """
  end
end
