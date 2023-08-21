defmodule ControlServerWeb.Live.Redis do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  import ControlServerWeb.RedisTable

  alias ControlServer.Redis

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :failover_clusters, list_failover_clusters())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Failover clusters")
    |> assign(:failover_cluster, nil)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    failover_cluster = Redis.get_failover_cluster!(id)
    {:ok, _} = Redis.delete_failover_cluster(failover_cluster)

    {:noreply, assign(socket, :failover_clusters, list_failover_clusters())}
  end

  defp list_failover_clusters do
    Redis.list_failover_clusters()
  end

  def new_url, do: ~p"/redis/new"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h1>Redis Clusters</.h1>
    <.redis_table failover_clusters={@failover_clusters} />

    <.h2>Actions</.h2>
    <.card>
      <.a navigate={new_url()}>
        <.button>
          New Cluster
        </.button>
      </.a>
    </.card>
    """
  end
end
