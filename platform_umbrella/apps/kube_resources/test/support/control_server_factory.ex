defmodule KubeResources.ControlServerFactory do
  @moduledoc """

  Factory for creating db represenetions needed in kube_resources
  """

  # with Ecto
  use ExMachina.Ecto, repo: ControlServer.Repo

  def notebook_factory do
    %ControlServer.Notebooks.JupyterLabNotebook{
      name: sequence("test-notebook")
    }
  end

  def postgres_factory do
    %ControlServer.Postgres.Cluster{
      name: sequence("test-postgres-cluster"),
      storage_size: "1G"
    }
  end

  def redis_factory do
    %ControlServer.Redis.FailoverCluster{
      name: sequence("test-redis-failover"),
      num_redis_instances: sequence(:num_redis_instances, [3, 5, 7, 9]),
      num_sentinel_instances: sequence(:num_sentinel_instances, [1, 2, 3])
    }
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
      nodes: [build(:ceph_storage_node), build(:ceph_storage_node)]
    }
  end

  def ceph_filesystem_factory do
    %ControlServer.Rook.CephFilesystem{
      name: sequence("test-ceph-filesystem"),
      include_erasure_encoded: sequence(:ec, [true, false])
    }
  end
end
