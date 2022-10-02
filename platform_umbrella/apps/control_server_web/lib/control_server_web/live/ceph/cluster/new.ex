defmodule ControlServerWeb.Live.CephClusterNew do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  alias ControlServer.Rook
  alias ControlServer.Rook.CephCluster
  alias ControlServer.Batteries.Installer
  alias ControlServerWeb.Live.CephClusterFormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    ceph_cluster = %CephCluster{
      num_mon: 3,
      num_mgr: 2,
      data_dir_host_path: "/var/lib/rook",
      name: MnemonicSlugs.generate_slug()
    }

    changeset = Rook.change_ceph_cluster(ceph_cluster)

    {:ok,
     socket
     |> assign(:ceph_cluster, ceph_cluster)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def update(%{ceph_cluster: ceph_cluster} = assigns, socket) do
    Logger.info("Update")
    changeset = Rook.change_ceph_cluster(ceph_cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_info({"ceph_cluster:save", %{"ceph_cluster" => ceph_cluster}}, socket) do
    new_path = Routes.ceph_cluster_show_path(socket, :show, ceph_cluster.id)
    Logger.debug("new_cluster = #{inspect(ceph_cluster)} new_path = #{new_path}")
    Installer.install!(:rook)

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>New Cluster</.title>
      </:title>
      <div>
        <.live_component
          module={CephClusterFormComponent}
          ceph_cluster={@ceph_cluster}
          id={@ceph_cluster.id || "new-cluster-form"}
          action={:new}
          save_target={self()}
        />
      </div>
    </.layout>
    """
  end
end
