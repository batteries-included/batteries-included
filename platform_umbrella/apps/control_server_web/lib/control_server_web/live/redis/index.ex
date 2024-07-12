defmodule ControlServerWeb.Live.Redis do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.RedisTable

  alias ControlServer.Redis

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(current_page: :data)
     |> assign_page_title("Redis Clusters")
     |> assign_failover_clusters()}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :failover_cluster, nil)
  end

  def assign_page_title(socket, page_title) do
    assign(socket, page_title: page_title)
  end

  defp assign_failover_clusters(socket) do
    assign(socket, :failover_clusters, list_failover_clusters())
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
    <.page_header title={@page_title} back_link={~p"/data"}>
      <.button variant="secondary" link={new_url()}>
        New Cluster
      </.button>
    </.page_header>
    <.panel title="All Clusters">
      <.redis_table rows={@failover_clusters} />
    </.panel>
    """
  end
end
