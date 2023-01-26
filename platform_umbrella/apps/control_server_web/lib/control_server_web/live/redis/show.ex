defmodule ControlServerWeb.Live.RedisShow do
  use ControlServerWeb, {:live_view, layout: :menu}

  import ControlServerWeb.LeftMenuPage
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable

  alias ControlServer.Redis
  alias KubeExt.KubeState
  alias KubeExt.OwnerLabel
  alias EventCenter.KubeState, as: KubeEventCenter

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
     |> assign(:id, id)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:failover_cluster, Redis.get_failover_cluster!(id))
     |> assign(:k8_failover, k8_failover(id))
     |> assign(:k8_services, k8_services(id))
     |> assign(:k8_pods, k8_pods(id))}
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

    {:noreply, push_redirect(socket, to: ~p"/redis")}
  end

  defp page_title(:show), do: "Show Redis Failover Cluster"

  defp edit_url(cluster),
    do: ~p"/redis/#{cluster}/edit"

  defp k8_failover(id) do
    Enum.find(KubeState.get_all(:redis_failover), nil, fn pg -> id == OwnerLabel.get_owner(pg) end)
  end

  defp k8_pods(id) do
    Enum.filter(KubeState.get_all(:pod), fn pg -> id == OwnerLabel.get_owner(pg) end)
  end

  defp k8_services(id) do
    Enum.filter(KubeState.get_all(:service), fn pg -> id == OwnerLabel.get_owner(pg) end)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.left_menu_page group={:data} active={:redis}>
      <.section_title>Pods</.section_title>
      <.pods_table pods={@k8_pods} />

      <.section_title>Services</.section_title>
      <.services_table services={@k8_services} />

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
    </.left_menu_page>
    """
  end
end
