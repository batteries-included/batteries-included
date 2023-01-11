defmodule ControlServerWeb.Live.CephIndex do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.CephFilesystemsTable
  import ControlServerWeb.CephClustersTable

  alias ControlServer.Rook

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:ceph_clusters, list_ceph_clusters())
     |> assign(:ceph_filesystems, list_ceph_filesystems())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Ceph Status")
    |> assign(:ceph_cluster, nil)
  end

  defp list_ceph_clusters do
    Rook.list_ceph_cluster()
  end

  defp list_ceph_filesystems do
    Rook.list_ceph_filesystem()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout group={:data} active={:rook}>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
      <.section_title>Ceph Clusters</.section_title>

      <.ceph_clusters_table ceph_clusters={@ceph_clusters} />

      <.section_title>Ceph FileSystem</.section_title>
      <.ceph_filesystems_table ceph_filesystems={@ceph_filesystems} />

      <.h2 variant="fancy">Actions</.h2>
      <.body_section>
        <.link navigate={~p"/ceph/clusters/new"}>
          <.button>
            New Cluster
          </.button>
        </.link>

        <.link navigate={~p"/ceph/filesystems/new"}>
          <.button>
            New FileSystem
          </.button>
        </.link>
      </.body_section>
    </.layout>
    """
  end
end
