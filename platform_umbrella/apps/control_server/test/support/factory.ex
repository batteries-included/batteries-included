defmodule ControlServer.Factory do
  @moduledoc """

  Factory for control_server ecto.
  """

  # with Ecto
  use ExMachina.Ecto, repo: ControlServer.Repo

  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Postgres
  alias CommonCore.Redis.FailoverCluster
  alias CommonCore.Rook.CephCluster
  alias CommonCore.Rook.CephFilesystem
  alias CommonCore.Rook.CephStorageNode

  def postgres_user_factory do
    %Postgres.PGUser{
      username: sequence("postgres_cluster-"),
      password: sequence("postgres_password-"),
      roles: ["login"]
    }
  end

  def postgres_cluster_factory do
    user_one = build(:postgres_user)
    user_two = build(:postgres_user)

    %Postgres.Cluster{
      name: sequence("postgres_cluster-"),
      num_instances: sequence(:num_instances, [1, 2, 5]),
      storage_size: 500 * 1024 * 1024,
      storage_class: "default",
      users: [user_one, user_two]
    }
  end

  def redis_cluster_factory do
    %FailoverCluster{
      name: sequence("redis-cluster-"),
      num_redis_instances: sequence(:num_redis_instances, [1, 2, 3, 4, 5, 9]),
      num_sentinel_instances: sequence(:num_sentinel_instances, [1, 2, 3, 4, 5, 9]),
      type: sequence(:redis_type, [:standard, :internal])
    }
  end

  def kube_notebook_factory do
    %JupyterLabNotebook{}
  end

  def ceph_storage_node_factory do
    %CephStorageNode{
      name: sequence("ceph-node"),
      device_filter: sequence(:device_filter, &"/dev/by-path/#{&1}-sata*")
    }
  end

  def ceph_cluster_factory do
    %CephCluster{
      name: sequence("test-ceph-cluster"),
      data_dir_host_path: "/var/lib/rook/ceph",
      num_mgr: 2,
      num_mon: 3,
      namespace: sequence("namespace-"),
      nodes: [build(:ceph_storage_node), build(:ceph_storage_node)]
    }
  end

  def ceph_filesystem_factory do
    %CephFilesystem{
      name: sequence("test-ceph-filesystem"),
      include_erasure_encoded: sequence(:include_erasure_encoded, [true, false])
    }
  end
end
