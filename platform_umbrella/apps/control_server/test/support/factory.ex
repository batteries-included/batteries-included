defmodule ControlServer.Factory do
  @moduledoc """

  Factory for control_server ecto.
  """

  # with Ecto
  use ExMachina.Ecto, repo: ControlServer.Repo

  def kube_notebook_factory do
    %ControlServer.Notebooks.JupyterLabNotebook{}
  end

  def ceph_storage_node_factory do
    %ControlServer.Rook.CephStorageNode{
      name: sequence("ceph-node"),
      device_filter: sequence(:device_filter, &"/dev/by-path/#{&1}-sata*")
    }
  end

  def ceph_cluster_factory do
    %ControlServer.Rook.CephCluster{
      name: sequence("test-ceph-cluster"),
      data_dir_host_path: "/var/lib/rook/ceph",
      num_mgr: 2,
      num_mon: 3,
      namespace: sequence("namespace-"),
      nodes: [build(:ceph_storage_node), build(:ceph_storage_node)]
    }
  end

  def ceph_filesystem_factory do
    %ControlServer.Rook.CephFilesystem{
      name: sequence("test-ceph-filesystem"),
      include_erasure_encoded: sequence(:include_erasure_encoded, [true, false])
    }
  end
end
