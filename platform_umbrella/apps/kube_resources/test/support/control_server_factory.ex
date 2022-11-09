defmodule KubeResources.ControlServerFactory do
  @moduledoc """

  Factory for creating db represenetions needed in kube_resources
  """

  # with Ecto
  use ExMachina

  def notebook_factory do
    %{
      name: sequence("test-notebook"),
      image: "jupyter/datascience-notebook:lab-3.2.9"
    }
  end

  def postgres_factory do
    %{
      name: sequence("test-postgres-cluster"),
      storage_size: "1G"
    }
  end

  def redis_factory do
    %{
      name: sequence("test-redis-failover"),
      num_redis_instances: sequence(:num_redis_instances, [3, 5, 7, 9]),
      num_sentinel_instances: sequence(:num_sentinel_instances, [1, 2, 3])
    }
  end

  def ceph_storage_node_factory do
    %{
      name: sequence("ceph-node"),
      device_filter: sequence(:device_filter, &"/dev/by-path/#{&1}-sata*")
    }
  end

  def ceph_cluster_factory do
    %{
      name: sequence("test-ceph-cluster"),
      data_dir_host_path: "/var/lib/rook/ceph",
      num_mgr: 2,
      num_mon: 3,
      nodes: [build(:ceph_storage_node), build(:ceph_storage_node)]
    }
  end

  def ceph_filesystem_factory do
    %{
      name: sequence("test-ceph-filesystem"),
      include_erasure_encoded: sequence(:ec, [true, false])
    }
  end

  def system_battery do
    %{
      config: %{},
      type:
        sequence(:type, [
          :alert_manager,
          :battery_core,
          :control_server,
          :data,
          :database_internal,
          :database_public,
          :dev_metallb,
          :echo_server,
          :gitea,
          :grafana,
          :harbor,
          :istio,
          :istio_gateway,
          :istio_istiod,
          :kiali,
          :knative,
          :knative_serving,
          :kube_state_metrics,
          :loki,
          :metallb,
          :ml_core,
          :monitoring_api_server,
          :monitoring_controller_manager,
          :monitoring_coredns,
          :monitoring_etcd,
          :monitoring_kube_proxy,
          :monitoring_kubelet,
          :monitoring_scheduler,
          :node_exporter,
          :notebooks,
          :ory_hydra,
          :postgres_operator,
          :prometheus,
          :prometheus_operator,
          :prometheus_stack,
          :promtail,
          :redis_operator,
          :redis,
          :rook,
          :ceph,
          :tekton_operator
        ])
    }
  end
end
