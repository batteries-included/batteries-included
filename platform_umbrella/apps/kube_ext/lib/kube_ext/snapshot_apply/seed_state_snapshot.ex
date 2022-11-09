defmodule KubeExt.SnapshotApply.SeedStateSnapshot do
  alias KubeExt.SnapshotApply.StateSnapshot
  alias KubeExt.RequiredDatabases

  def seed, do: seed(KubeExt.cluster_type())

  def seed(:everything) do
    %StateSnapshot{
      system_batteries:
        Enum.map(
          [
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
          ],
          &default_battery/1
        ),
      postgres_clusters: [
        RequiredDatabases.Control.control_cluster(),
        RequiredDatabases.Gitea.gitea_cluster(),
        RequiredDatabases.Harbor.harbor_pg_cluster(),
        RequiredDatabases.OryHydra.hydra_cluster()
      ],
      redis_clusters: [RequiredDatabases.Harbor.harbor_redis_cluster()]
    }
  end

  def seed(_type) do
    %StateSnapshot{
      system_batteries:
        Enum.map(
          [:battery_core, :data, :postgres_operator, :database_internal, :istio, :istio_istiod],
          &default_battery/1
        ),
      postgres_clusters: [RequiredDatabases.Control.control_cluster()]
    }
  end

  defp default_battery(type) do
    %{
      type: type,
      config: %{}
    }
  end
end
