defmodule ControlServerWeb.Live.CephIndex do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import CommonUI.Table

  alias ControlServer.Rook

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:ceph_clusters, list_ceph_clusters())
     |> assign(:ceph_filesystems, list_ceph_filesystems())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Ceph Status")
    |> assign(:ceph_cluster, nil)
  end

  def show_cluster_url(ceph_cluster),
    do: Routes.ceph_cluster_show_path(ControlServerWeb.Endpoint, :show, ceph_cluster)

  def show_filesystem_url(ceph_filesystem),
    do: Routes.ceph_filesystem_show_path(ControlServerWeb.Endpoint, :show, ceph_filesystem)

  def new_cluster_url, do: Routes.ceph_cluster_new_path(ControlServerWeb.Endpoint, :new)
  def new_filesystem_url, do: Routes.ceph_filesystem_new_path(ControlServerWeb.Endpoint, :new)

  defp list_ceph_clusters do
    Rook.list_ceph_cluster()
  end

  defp list_ceph_filesystems do
    Rook.list_ceph_filesystem()
  end

  defp clusters_section(assigns) do
    ~H"""
    <.table>
      <.thead>
        <.tr>
          <.th>Name</.th>
          <.th>Num mon</.th>
          <.th>Num mgr</.th>
          <.th>Data dir host path</.th>

          <.th>Action</.th>
        </.tr>
      </.thead>
      <.tbody id="ceph_cluster">
        <%= for ceph_cluster <- @ceph_clusters do %>
          <.tr id={"ceph_cluster-#{ceph_cluster.id}"}>
            <.td><%= ceph_cluster.name %></.td>
            <.td><%= ceph_cluster.num_mon %></.td>
            <.td><%= ceph_cluster.num_mgr %></.td>
            <.td><%= ceph_cluster.data_dir_host_path %></.td>

            <.td>
              <.link to={show_cluster_url(ceph_cluster)} class="mt-8 text-lg font-medium text-left">
                Show Cluster
              </.link>
            </.td>
          </.tr>
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp filesystems_section(assigns) do
    ~H"""
    <.table>
      <.thead>
        <.tr>
          <.th>Name</.th>
          <.th>Include EC</.th>

          <.th>Action</.th>
        </.tr>
      </.thead>
      <.tbody id="ceph_filesystems">
        <%= for fs <- @ceph_filesystems do %>
          <.tr id={"ceph_fs-#{fs.id}"}>
            <.td><%= fs.name %></.td>
            <.td><%= fs.include_erasure_encoded %></.td>

            <.td>
              <.link to={show_filesystem_url(fs)} class="mt-8 text-lg font-medium text-left">
                Show FileSystem
              </.link>
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
      <.section_title>Ceph Clusters</.section_title>

      <.body_section>
        <.clusters_section ceph_clusters={@ceph_clusters} />
      </.body_section>

      <.section_title>Ceph FileSystem</.section_title>
      <.body_section>
        <.filesystems_section ceph_filesystems={@ceph_filesystems} />
      </.body_section>

      <.h3>Actions</.h3>
      <.body_section>
        <.link to={new_cluster_url()}>
          <.button>
            New Cluster
          </.button>
        </.link>

        <.link to={new_filesystem_url()}>
          <.button>
            New FileSystem
          </.button>
        </.link>
      </.body_section>
    </.layout>
    """
  end
end
