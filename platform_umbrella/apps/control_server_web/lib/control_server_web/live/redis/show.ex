defmodule ControlServerWeb.Live.RedisShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable

  alias CommonCore.Util.Memory
  alias ControlServer.Redis
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = KubeEventCenter.subscribe(:pod)
    :ok = KubeEventCenter.subscribe(:service)
    :ok = KubeEventCenter.subscribe(:redis_failover)
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign_timeline_installed()
     |> assign(:id, id)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:failover_cluster, Redis.get_failover_cluster!(id, preload: [:project]))
     |> assign(:k8_failover, k8_failover(id))
     |> assign(:k8_services, k8_services(id))
     |> assign(:k8_pods, k8_pods(id))}
  end

  defp assign_timeline_installed(socket) do
    assign(socket, :timeline_installed, SummaryBatteries.battery_installed(:timeline))
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply,
     socket
     |> assign(:k8_failover, k8_failover(socket.assigns.id))
     |> assign(:k8_services, k8_services(socket.assigns.id))
     |> assign(:k8_pods, k8_pods(socket.assigns.id))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = Redis.delete_failover_cluster(socket.assigns.failover_cluster)

    {:noreply, push_navigate(socket, to: ~p"/redis")}
  end

  @impl Phoenix.LiveView
  def render(%{live_action: :show} = assigns) do
    ~H"""
    <.page_header title={"Redis Cluster: #{@failover_cluster.name}"} back_link={~p"/redis"}>
      <:menu>
        <.badge :if={@failover_cluster.project_id}>
          <:item label="Project"><%= @failover_cluster.project.name %></:item>
        </.badge>
      </:menu>

      <.flex>
        <.tooltip target_id="edit-tooltip">Edit Cluster</.tooltip>
        <.tooltip target_id="delete-tooltip">Delete Cluster</.tooltip>
        <.flex gaps="0">
          <.button id="edit-tooltip" variant="icon" icon={:pencil} link={edit_url(@failover_cluster)} />
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
            <%= @failover_cluster.num_redis_instances %>
          </:item>
          <:item title="Sentinel Instances">
            <%= @failover_cluster.num_sentinel_instances %>
          </:item>
          <:item :if={@failover_cluster.memory_limits} title="Memory Limits">
            <%= Memory.humanize(@failover_cluster.memory_limits) %>
          </:item>
          <:item title="Started">
            <.relative_display time={creation_timestamp(@k8_failover)} />
          </:item>
        </.data_list>
      </.panel>

      <.flex column class="justify-start">
        <.a variant="bordered" navigate={services_url(@failover_cluster)}>Services</.a>
      </.flex>

      <.panel title="Pods" class="col-span-2">
        <.pods_table pods={@k8_pods} />
      </.panel>
    </.grid>
    """
  end

  @impl Phoenix.LiveView
  def render(%{live_action: :services} = assigns) do
    ~H"""
    <.page_header title="Services" back_link={show_url(@failover_cluster)} />

    <.panel>
      <.services_table services={@k8_services} />
    </.panel>
    """
  end

  defp page_title(:show), do: "Redis Cluster"
  defp page_title(:services), do: "Redis Cluster Services"

  defp edit_url(failover_cluster), do: ~p"/redis/#{failover_cluster}/edit"
  defp show_url(failover_cluster), do: ~p"/redis/#{failover_cluster}/show"
  defp services_url(failover_cluster), do: ~p"/redis/#{failover_cluster}/services"

  defp k8_failover(id) do
    Enum.find(KubeState.get_all(:redis_failover), nil, fn pg -> id == labeled_owner(pg) end)
  end

  defp k8_pods(id) do
    Enum.filter(KubeState.get_all(:pod), fn pg -> id == labeled_owner(pg) end)
  end

  defp k8_services(id) do
    Enum.filter(KubeState.get_all(:service), fn pg -> id == labeled_owner(pg) end)
  end
end
