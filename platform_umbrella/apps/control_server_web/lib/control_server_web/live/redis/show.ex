defmodule ControlServerWeb.Live.RedisShow do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.PodsDisplay
  import ControlServerWeb.ServicesDisplay

  alias ControlServer.Redis
  alias KubeExt.KubeState
  alias KubeExt.OwnerLabel
  alias EventCenter.KubeState, as: KubeEventCenter

  @impl true
  def mount(_params, _session, socket) do
    :ok = KubeEventCenter.subscribe(:pod)
    :ok = KubeEventCenter.subscribe(:service)
    :ok = KubeEventCenter.subscribe(:redis_failover)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:id, id)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:failover_cluster, Redis.get_failover_cluster!(id))
     |> assign(:k8_failover, k8_failover(id))
     |> assign(:k8_services, k8_services(id))
     |> assign(:k8_pods, k8_pods(id))}
  end

  @impl true
  def handle_info(_unused, socket) do
    {:noreply,
     socket
     |> assign(:k8_failover, k8_failover(socket.assigns.id))
     |> assign(:k8_services, k8_services(socket.assigns.id))
     |> assign(:k8_pods, k8_pods(socket.assigns.id))}
  end

  @impl true
  def handle_event("delete", _, socket) do
    {:ok, _} = Redis.delete_failover_cluster(socket.assigns.failover_cluster)

    {:noreply, push_redirect(socket, to: Routes.redis_path(socket, :index))}
  end

  defp page_title(:show), do: "Show Redis Failover Cluster"

  defp edit_url(failover_cluster),
    do: Routes.redis_edit_path(ControlServerWeb.Endpoint, :edit, failover_cluster.id)

  defp k8_failover(id) do
    Enum.find(KubeState.redis_failovers(), nil, fn pg -> id == OwnerLabel.get_owner(pg) end)
  end

  defp k8_pods(id) do
    Enum.filter(KubeState.pods(), fn pg -> id == OwnerLabel.get_owner(pg) end)
  end

  defp k8_services(id) do
    Enum.filter(KubeState.services(), fn pg -> id == OwnerLabel.get_owner(pg) end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
      <:left_menu>
        <.data_menu active="redis" />
      </:left_menu>

      <.section_title>Pods</.section_title>
      <.pods_display pods={@k8_pods} />

      <.section_title>Services</.section_title>
      <.services_display services={@k8_services} />

      <.h2>Actions</.h2>
      <.body_section>
        <.link navigate={edit_url(@failover_cluster)}>
          <.button>
            Edit Cluster
          </.button>
        </.link>

        <.button phx-click="delete" data-confirm="Are you sure?">
          Delete Cluster
        </.button>
      </.body_section>
    </.layout>
    """
  end
end
