defmodule ControlServerWeb.Live.CephFilesystemEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias ControlServer.Rook
  alias ControlServerWeb.Live.CephFilesystemFormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :ceph_filesystem, Rook.get_ceph_filesystem!(id))}
  end

  @impl Phoenix.LiveView
  def handle_info({"ceph_filesystem:save", %{"ceph_filesystem" => ceph_filesystem}}, socket) do
    {:noreply, push_redirect(socket, to: ~p"/ceph/filesystems/#{ceph_filesystem}/show")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={CephFilesystemFormComponent}
        ceph_filesystem={@ceph_filesystem}
        id={@ceph_filesystem.id || "edit-ceph_filesystem-form"}
        action={:edit}
        save_target={self()}
      />
    </div>
    """
  end
end
