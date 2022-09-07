defmodule ControlServerWeb.Live.Redis do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import CommonUI.Table

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

  def show_url(failover_cluster),
    do: Routes.redis_show_path(ControlServerWeb.Endpoint, :show, failover_cluster)

  def new_url, do: Routes.redis_new_path(ControlServerWeb.Endpoint, :new)

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Redis Clusters</.title>
      </:title>
      <:left_menu>
        <.data_menu active="redis" />
      </:left_menu>
      <.section_title>
        Redis Clusters
      </.section_title>
      <.body_section>
        <.table>
          <.thead>
            <.tr>
              <.th>Name</.th>
              <.th>Action</.th>
            </.tr>
          </.thead>
          <.tbody id="failover_clusters">
            <%= for failover_cluster <- @failover_clusters do %>
              <.tr id={"failover_cluster-#{failover_cluster.id}"}>
                <.td><%= failover_cluster.name %></.td>
                <.td>
                  <.link to={show_url(failover_cluster)} class="mt-8 text-lg font-medium text-left">
                    Show Cluster
                  </.link>
                </.td>
              </.tr>
            <% end %>
          </.tbody>
        </.table>
      </.body_section>

      <.h3>Actions</.h3>
      <.body_section>
        <.link to={new_url()}>
          <.button>
            New Cluster
          </.button>
        </.link>
      </.body_section>
    </.layout>
    """
  end
end
