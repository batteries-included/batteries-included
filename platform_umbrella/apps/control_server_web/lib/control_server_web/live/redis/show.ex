defmodule ControlServerWeb.Live.RedisShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  import CommonCore.Resources.FieldAccessors, only: [labeled_owner: 1]
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable

  alias ControlServer.Redis
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

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

  defp edit_url(cluster), do: ~p"/redis/#{cluster}/edit"

  defp k8_failover(id) do
    Enum.find(KubeState.get_all(:redis_failover), nil, fn pg -> id == labeled_owner(pg) end)
  end

  defp k8_pods(id) do
    Enum.filter(KubeState.get_all(:pod), fn pg -> id == labeled_owner(pg) end)
  end

  defp k8_services(id) do
    Enum.filter(KubeState.get_all(:service), fn pg -> id == labeled_owner(pg) end)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h1>
      Redis
      <:sub_header><%= @failover_cluster.name %></:sub_header>
    </.h1>
    <.h2>Pods</.h2>
    <.pods_table pods={@k8_pods} />

    <.h2>Services</.h2>
    <.services_table services={@k8_services} />

    <.h2>Actions</.h2>
    <.card>
      <div class="grid md:grid-cols-2 gap-6">
        <.a navigate={edit_url(@failover_cluster)} class="block">
          <.button class="w-full">
            Edit Cluster
          </.button>
        </.a>

        <.button phx-click="delete" data-confirm="Are you sure?" class="w-full">
          Delete Cluster
        </.button>
      </div>
    </.card>
    """
  end
end
