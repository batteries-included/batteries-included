defmodule ControlServerWeb.Live.CephClusterShow do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import CommonUI.Table

  alias ControlServer.Rook

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:ceph_cluster, Rook.get_ceph_cluster!(id))}
  end

  defp page_title(:show), do: "Show Ceph cluster"

  defp nodes_list(assigns) do
    ~H"""
    <.table>
      <.thead>
        <.tr>
          <.th>
            Name
          </.th>
          <.th>
            Device Filter
          </.th>
        </.tr>
      </.thead>
      <.tbody>
        <%= for node <- @nodes do %>
          <.tr>
            <.td>
              <%= node.name %>
            </.td>
            <.td>
              <%= node.device_filter %>
            </.td>
          </.tr>
        <% end %>
      </.tbody>
    </.table>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
      <:left_menu>
        <.data_menu active="ceph_cluster" />
      </:left_menu>
      <.h3>Cluster Summary</.h3>
      <.body_section>
        <ul>
          <li>
            <strong>Name:</strong>
            <%= @ceph_cluster.name %>
          </li>

          <li>
            <strong>Num mon:</strong>
            <%= @ceph_cluster.num_mon %>
          </li>

          <li>
            <strong>Num mgr:</strong>
            <%= @ceph_cluster.num_mgr %>
          </li>

          <li>
            <strong>Data dir host path:</strong>
            <%= @ceph_cluster.data_dir_host_path %>
          </li>
        </ul>
      </.body_section>

      <.h3>Nodes</.h3>
      <.body_section>
        <.nodes_list nodes={@ceph_cluster.nodes} />
      </.body_section>

      <span>
        <%= live_patch("Edit",
          to: Routes.ceph_cluster_edit_path(@socket, :edit, @ceph_cluster),
          class: "button"
        ) %>
      </span>
      | <span><%= live_redirect("Back", to: Routes.ceph_index_path(@socket, :index)) %></span>
    </.layout>
    """
  end
end
