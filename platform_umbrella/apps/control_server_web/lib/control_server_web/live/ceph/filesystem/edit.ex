defmodule ControlServerWeb.Live.CephFilesystemEdit do
  use ControlServerWeb, :live_view

  import ControlServerWeb.MenuLayout

  alias ControlServer.Rook
  alias ControlServerWeb.Live.CephFilesystemFormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :ceph_filesystem, Rook.get_ceph_filesystem!(id))}
  end

  @impl true
  def handle_info({"ceph_filesystem:save", %{"ceph_filesystem" => ceph_filesystem}}, socket) do
    {:noreply, push_redirect(socket, to: ~p"/ceph/filesystems/#{ceph_filesystem}/show")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.menu_layout group={:devtools}>
      <:title>
        <.title>Edit Cluster</.title>
      </:title>
      <div>
        <.live_component
          module={CephFilesystemFormComponent}
          ceph_filesystem={@ceph_filesystem}
          id={@ceph_filesystem.id || "edit-ceph_filesystem-form"}
          action={:edit}
          save_target={self()}
        />
      </div>
    </.menu_layout>
    """
  end
end
