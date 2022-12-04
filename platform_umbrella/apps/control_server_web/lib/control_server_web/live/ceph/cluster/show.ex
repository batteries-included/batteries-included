defmodule ControlServerWeb.Live.CephClusterShow do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.Rook

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:ceph_cluster, Rook.get_ceph_cluster!(id))}
  end

  defp page_title(:show), do: "Show Ceph cluster"

  defp nodes_list(assigns) do
    ~H"""
    <.table id="assigned-nodes-table" rows={@nodes}>
      <:col :let={node} label="Name"><%= node.name %></:col>
      <:col :let={node} label="Device Filter"><%= node.device_filter %></:col>
    </.table>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout group={:data} active={:rook}>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
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

      <.section_title>Nodes</.section_title>
      <.body_section>
        <.nodes_list nodes={@ceph_cluster.nodes} />
      </.body_section>

      <span>
        <%= live_patch("Edit", to: ~p"/ceph/clusters/#{@ceph_cluster}/show", class: "button") %>
      </span>
      | <span><%= live_redirect("Back", to: ~p"/ceph/clusters/#{@ceph_cluster}/show") %></span>
    </.layout>
    """
  end
end
