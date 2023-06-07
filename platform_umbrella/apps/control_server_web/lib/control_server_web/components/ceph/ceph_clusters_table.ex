defmodule ControlServerWeb.CephClustersTable do
  use ControlServerWeb, :html

  attr :ceph_clusters, :list, required: true

  def ceph_clusters_table(assigns) do
    ~H"""
    <.table rows={@ceph_clusters}>
      <:col :let={ceph} label="Name"><%= ceph.name %></:col>
      <:col :let={ceph} label="Monitors"><%= ceph.num_mon %></:col>
      <:col :let={ceph} label="Managers"><%= ceph.num_mgr %></:col>
      <:col :let={ceph} label="Data dir"><%= ceph.data_dir_host_path %></:col>
      <:action :let={ceph}>
        <.a navigate={~p"/ceph/clusters/#{ceph}/show"} variant="styled">
          Show Cluster
        </.a>
      </:action>
    </.table>
    """
  end
end
