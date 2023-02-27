defmodule ControlServerWeb.Live.CephClusterShow do
  use ControlServerWeb, {:live_view, layout: :fresh}

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

  defp page_title(_), do: "Show Ceph cluster"

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
    <.card>
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
    </.card>

    <.h2>Nodes</.h2>
    <.card>
      <.nodes_list nodes={@ceph_cluster.nodes} />
    </.card>

    <span>
      <%= live_patch("Edit", to: ~p"/ceph/clusters/#{@ceph_cluster}/show", class: "button") %>
    </span>
    | <span><%= live_redirect("Back", to: ~p"/ceph/clusters/#{@ceph_cluster}/show") %></span>
    """
  end
end
