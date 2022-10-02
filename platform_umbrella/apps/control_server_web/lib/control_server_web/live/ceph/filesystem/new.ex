defmodule ControlServerWeb.Live.CephFilesystemNew do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  alias ControlServer.Rook
  alias ControlServer.Rook.CephFilesystem
  alias ControlServer.Batteries.Installer
  alias ControlServerWeb.Live.CephFilesystemFormComponent

  require Logger

  @impl true
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

  @impl true
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

  @impl true
  def handle_info({"ceph_filesystem:save", %{"ceph_filesystem" => ceph_filesystem}}, socket) do
    new_path = Routes.ceph_filesystem_show_path(socket, :show, ceph_filesystem.id)
    Logger.debug("new filesystem = #{inspect(ceph_filesystem)} new_path = #{new_path}")
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
          module={CephFilesystemFormComponent}
          ceph_filesystem={@ceph_filesystem}
          id={@ceph_filesystem.id || "new-filesystem-form"}
          action={:new}
          save_target={self()}
        />
      </div>
    </.layout>
    """
  end
end
