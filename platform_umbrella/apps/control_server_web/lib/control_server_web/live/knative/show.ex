defmodule ControlServerWeb.Live.KnativeShow do
  @moduledoc """
  LiveView to display all the most relevant status of a Knative Service.

  This depends on the Knative operator being installed and
  the owned resources being present in kubernetes.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import CommonUI.DatetimeDisplay
  import ControlServerWeb.Chart
  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.Knative.EnvValuePanel

  alias CommonCore.Resources.OwnerReference
  alias ControlServer.Knative
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = KubeEventCenter.subscribe(:pod)
    :ok = KubeEventCenter.subscribe(:knative_service)
    :ok = KubeEventCenter.subscribe(:knative_revision)
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    service = Knative.get_service!(id)

    {:noreply,
     socket
     |> assign(:id, id)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:service, service)
     |> assign_k8s(service)}
  end

  defp assign_k8s(socket, service) do
    k8_service = k8_service(service)
    k8_configuration = k8_configuration(k8_service)

    socket
    |> assign(:k8_service, k8_service)
    |> assign(:k8_configuration, k8_configuration)
    |> assign(:k8_revisions, k8_revisions(k8_configuration))
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, assign_k8s(socket, socket.assigns.service)}
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

    {:noreply, push_redirect(socket, to: ~p"/knative/services")}
  end

  defp page_title(:show), do: "Show Knative Service"

  defp edit_url(service), do: ~p"/knative/services/#{service}/edit"

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

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header
      title={@page_title}
      back_button={%{link_type: "live_redirect", to: ~p"/knative/services"}}
    >
      <:menu>
        <.flex>
          <.button>Edit History</.button>

          <.flex gaps="0">
            <PC.icon_button to={edit_url(@service)} link_type="live_redirect">
              <Heroicons.pencil solid />
            </PC.icon_button>

            <PC.icon_button type="button" phx-click="delete" data-confirm="Are you sure?">
              <Heroicons.trash />
            </PC.icon_button>
          </.flex>
        </.flex>
      </:menu>
    </.page_header>

    <.flex column>
      <.data_horizontal_bordered>
        <:item title="Name">
          <%= @service.name %>
        </:item>
        <:item title="Namespace"><%= namespace(@k8_service) %></:item>
        <:item title="Started">
          <.relative_display time={creation_timestamp(@k8_service)} />
        </:item>
        <:item title="Url">
          <.a href={service_url(@k8_service)} variant="external">
            <%= service_url(@k8_service) %>
          </.a>
        </:item>
      </.data_horizontal_bordered>

      <.service_display service={@k8_service} revisions={@k8_revisions} />
      <.env_var_panel env_values={@service.env_values} />
    </.flex>
    """
  end
end
