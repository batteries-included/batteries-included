defmodule ControlServerWeb.Live.CephClusterEdit do
  use ControlServerWeb, :live_view

  import ControlServerWeb.MenuLayout

  alias ControlServer.Rook
  alias ControlServerWeb.Live.CephClusterFormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :ceph_cluster, Rook.get_ceph_cluster!(id))}
  end

  @impl Phoenix.LiveView
  def handle_info({"ceph_cluster:save", %{"ceph_cluster" => ceph_cluster}}, socket) do
    {:noreply, push_redirect(socket, to: ~p"/ceph/clusters/#{ceph_cluster}/show")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.menu_layout>
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
    </.menu_layout>
    """
  end
end
