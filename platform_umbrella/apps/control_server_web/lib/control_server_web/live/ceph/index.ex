defmodule ControlServerWeb.Live.CephIndex do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

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
    <.table rows={@ceph_clusters} id="clusters-table">
      <:col :let={ceph} label="Name"><%= ceph.name %></:col>
      <:col :let={ceph} label="Monitors"><%= ceph.num_mon %></:col>
      <:col :let={ceph} label="Managers"><%= ceph.num_mgr %></:col>
      <:col :let={ceph} label="Data dir"><%= ceph.data_dir_host_path %></:col>
      <:action :let={ceph}>
        <.link navigate={show_cluster_url(ceph)} type="styled">
          Show Cluster
        </.link>
      </:action>
    </.table>
    """
  end

  defp filesystems_section(assigns) do
    ~H"""
    <.table rows={@ceph_filesystems} id="filesystems-table">
      <:col :let={ceph} label="Name"><%= ceph.name %></:col>
      <:col :let={ceph} label="Include EC?"><%= ceph.include_erasure_encoded %></:col>
      <:action :let={ceph}>
        <.link navigate={show_filesystem_url(ceph)} type="styled">
          Show FileSystem
        </.link>
      </:action>
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

      <.clusters_section ceph_clusters={@ceph_clusters} />

      <.section_title>Ceph FileSystem</.section_title>
      <.filesystems_section ceph_filesystems={@ceph_filesystems} />

      <.h2>Actions</.h2>
      <.body_section>
        <.link navigate={new_cluster_url()}>
          <.button>
            New Cluster
          </.button>
        </.link>

        <.link navigate={new_filesystem_url()}>
          <.button>
            New FileSystem
          </.button>
        </.link>
      </.body_section>
    </.layout>
    """
  end
end
