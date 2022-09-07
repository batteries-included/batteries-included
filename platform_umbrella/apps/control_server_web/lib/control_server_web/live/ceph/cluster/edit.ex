defmodule ControlServerWeb.Live.CephClusterEdit do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  alias ControlServer.Rook
  alias ControlServerWeb.Live.CephClusterFormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :ceph_cluster, Rook.get_ceph_cluster!(id))}
  end

  @impl true
  def handle_info({"ceph_cluster:save", %{"ceph_cluster" => ceph_cluster}}, socket) do
    new_path = show_url(ceph_cluster)
    Logger.debug("updated ceph_cluster = #{inspect(ceph_cluster)} new_path = #{new_path}")

    {:noreply, push_redirect(socket, to: new_path)}
  end

  defp show_url(ceph_cluster),
    do: Routes.ceph_cluster_show_path(ControlServerWeb.Endpoint, :show, ceph_cluster.id)

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Edit Cluster</.title>
      </:title>
      <div>
        <.live_component
          module={CephClusterFormComponent}
          ceph_cluster={@ceph_cluster}
          id={@ceph_cluster.id || "edit-ceph_cluster-form"}
          action={:edit}
          save_target={self()}
        />
      </div>
    </.layout>
    """
  end
end
