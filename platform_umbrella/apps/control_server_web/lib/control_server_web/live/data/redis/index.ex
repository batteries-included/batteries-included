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

  def edit_url(failover_cluster),
    do: Routes.redis_edit_path(ControlServerWeb.Endpoint, :edit, failover_cluster)

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
      <.body_section>
        <.h3>
          Redis Clusters
        </.h3>
        <.table>
          <.thead>
            <.tr>
              <.th>Name</.th>
              <.th>Num sentinel instances</.th>
              <.th>Num redis instances</.th>
              <.th></.th>
            </.tr>
          </.thead>
          <.tbody id="failover_clusters">
            <%= for failover_cluster <- @failover_clusters do %>
              <.tr id={"failover_cluster-#{failover_cluster.id}"}>
                <.td><%= failover_cluster.name %></.td>
                <.td><%= failover_cluster.num_sentinel_instances %></.td>
                <.td><%= failover_cluster.num_redis_instances %></.td>

                <.td>
                  <span>
                    <.link to={edit_url(failover_cluster)}>Edit Cluster</.link>
                  </span>
                  <span>
                    <.link
                      to="#"
                      phx-click="delete"
                      phx-value-id={failover_cluster.id}
                      data={[confirm: "Are you sure?"]}
                    >
                      Delete
                    </.link>
                  </span>
                </.td>
              </.tr>
            <% end %>
          </.tbody>
        </.table>

        <div class="ml-8 mt-15">
          <.button type="primary" variant="shadow" to={new_url()} link_type="live_patch">
            New Cluster
          </.button>
        </div>
      </.body_section>
    </.layout>
    """
  end
end
