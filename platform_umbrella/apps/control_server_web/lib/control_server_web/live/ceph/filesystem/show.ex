defmodule ControlServerWeb.Live.CephFilesystemShow do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.Rook

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:ceph_filesystem, Rook.get_ceph_filesystem!(id))}
  end

  defp page_title(:show), do: "Show Ceph Filesystem"

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
      <:left_menu>
        <.data_menu active="ceph_filesystem" />
      </:left_menu>
      <.h3>FileSystem Summary</.h3>
      <.body_section>
        <ul>
          <li>
            <strong>Name:</strong>
            <%= @ceph_filesystem.name %>
          </li>

          <li>
            <strong>Include Erasure Encoding:</strong>
            <%= @ceph_filesystem.include_erasure_encoded %>
          </li>
        </ul>
      </.body_section>

      <span>
        <%= live_patch("Edit",
          to: Routes.ceph_filesystem_edit_path(@socket, :edit, @ceph_filesystem),
          class: "button"
        ) %>
      </span>
      | <span><%= live_redirect("Back", to: Routes.ceph_index_path(@socket, :index)) %></span>
    </.layout>
    """
  end
end
