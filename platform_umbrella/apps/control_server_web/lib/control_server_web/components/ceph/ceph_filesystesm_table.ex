defmodule ControlServerWeb.CephFilesystemsTable do
  use ControlServerWeb, :html

  attr :ceph_filesystems, :list, required: true

  def ceph_filesystems_table(assigns) do
    ~H"""
    <.table rows={@ceph_filesystems}>
      <:col :let={ceph} label="Name"><%= ceph.name %></:col>
      <:col :let={ceph} label="Include EC?"><%= ceph.include_erasure_encoded %></:col>
      <:action :let={ceph}>
        <.link navigate={~p"/ceph/filesystems/#{ceph}/show"} variant="styled">
          Show FileSystem
        </.link>
      </:action>
    </.table>
    """
  end
end
