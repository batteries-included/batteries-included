defmodule ControlServerWeb.Live.CephFilesystemNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias CommonCore.Rook.CephFilesystem
  alias ControlServer.Batteries.Installer
  alias ControlServer.Rook
  alias ControlServerWeb.Live.CephFilesystemFormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    ceph_filesystem = %CephFilesystem{
      name: MnemonicSlugs.generate_slug(),
      include_erasure_encoded: true
    }

    changeset = Rook.change_ceph_filesystem(ceph_filesystem)

    {:ok,
     socket
     |> assign(:ceph_filesystem, ceph_filesystem)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def update(%{ceph_filesystem: ceph_filesystem} = assigns, socket) do
    Logger.info("Update")
    changeset = Rook.change_ceph_filesystem(ceph_filesystem)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveView
  def handle_info({"ceph_filesystem:save", %{"ceph_filesystem" => ceph_filesystem}}, socket) do
    Installer.install!(:rook)

    {:noreply, push_redirect(socket, to: ~p"/ceph/filesystems/#{ceph_filesystem}/show")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={CephFilesystemFormComponent}
        ceph_filesystem={@ceph_filesystem}
        id={@ceph_filesystem.id || "new-filesystem-form"}
        action={:new}
        save_target={self()}
      />
    </div>
    """
  end
end
