defmodule ControlServerWeb.Live.Redis do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.Redis

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :failover_clusters, list_failover_clusters())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Failover clusters")
    |> assign(:failover_cluster, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    failover_cluster = Redis.get_failover_cluster!(id)
    {:ok, _} = Redis.delete_failover_cluster(failover_cluster)

    {:noreply, assign(socket, :failover_clusters, list_failover_clusters())}
  end

  defp list_failover_clusters do
    Redis.list_failover_clusters()
  end

  def show_url(cluster),
    do: ~p"/redis/clusters/#{cluster}/show"

  def new_url, do: ~p"/redis/clusters/new"

  @impl true
  def render(assigns) do
    ~H"""
    <.layout group={:data} active={:redis}>
      <:title>
        <.title>Redis Clusters</.title>
      </:title>
      <.table id="redis-display-table" rows={@failover_clusters}>
        <:col :let={redis} label="Name"><%= redis.name %></:col>
        <:col :let={redis} label="Instances"><%= redis.num_redis_instances %></:col>
        <:col :let={redis} label="Sentinel Instances"><%= redis.num_sentinel_instances %></:col>
        <:action :let={redis}>
          <.link navigate={show_url(redis)} type="styled">
            Show Redis Cluster
          </.link>
        </:action>
      </.table>

      <.h2>Actions</.h2>
      <.body_section>
        <.link navigate={new_url()}>
          <.button>
            New Cluster
          </.button>
        </.link>
      </.body_section>
    </.layout>
    """
  end
end
