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

  def jupyter_notebook_factory do
    %JupyterLabNotebook{name: sequence("kube-notebook-")}
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

  def knative_container_factory do
    %CommonCore.Knative.Container{name: sequence("knative-container-"), image: "nginx:latest"}
  end

  def knative_env_value_factory do
    %CommonCore.Knative.EnvValue{name: sequence("env-value-"), value: "test", source_type: :value}
  end

  @spec knative_service_factory() :: CommonCore.Knative.Service.t()
  def knative_service_factory do
    %CommonCore.Knative.Service{
      name: sequence("knative-service-"),
      rollout_duration: sequence(:rollout_duration, ["10s", "1m", "2m", "10m", "20m", "30m"]),
      oauth2_proxy: sequence(:oauth2_proxy, [true, false]),
      containers: [build(:knative_container)],
      env_values: [build(:knative_env_value), build(:knative_env_value)]
    }
  end
end
