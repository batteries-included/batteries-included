defmodule KubeResources.ConfigGenerator do
  @moduledoc """
  Given any BaseService this will extract the kubernetes configs for application to the cluster.
  """
  alias KubeExt.Builder, as: B

  alias ControlServer.Services.BaseService

  alias KubeRawResources.{Battery, IstioBase, IstioIstiod, PostgresOperator}

  alias KubeResources.{
    CertManager,
    ControlServerResources,
    Data,
    Database,
    EchoServer,
    Gitea,
    IstioGateway,
    Keycloak,
    Kiali,
    KnativeOperator,
    KnativeServing,
    ML,
    Notebooks,
    Redis,
    VirtualService,
    Tekton,
    TektonDashboard,
    OryHydra,
    Harbor,
    Rook,
    Ceph,
    PrometheusOperator,
    Prometheus,
    Grafana,
    Alertmanager,
    NodeExporter,
    KubeStateMetrics,
    Loki,
    Promtail,
    MonitoringApiServer,
    MonitoringControllerManager,
    MonitoringCoredns,
    MonitoringEtcd,
    MonitoringKubeProxy,
    MonitoringKubelet,
    MonitoringScheduler,
    PrometheusStack,
    MetalLB,
    DevMetalLB
  }

  require Logger

  @spec materialize(BaseService.t()) :: map()
  def materialize(%BaseService{} = base_service) do
    base_service.config
    |> materialize(base_service.service_type)
    |> Enum.map(fn {key, value} -> {Path.join(base_service.root_path, key), value} end)
    |> Enum.flat_map(&flatten/1)
    |> Enum.map(fn {key, resource} -> {key, B.owner_label(resource, base_service.id)} end)
    |> Enum.into(%{})
  end

  defp flatten({key, values} = _input) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.reject(fn {_key, resource} -> resource == nil end)
    |> Enum.map(fn {v, idx} ->
      {Path.join(key, Integer.to_string(idx)), v}
    end)
  end

  defp flatten({key, value}), do: [{key, value}]

  def materialize(%{} = config, :istio_gateway) do
    config |> IstioGateway.materialize() |> Map.merge(VirtualService.materialize(config))
  end

  def materialize(%{} = config, :rook) do
    config |> Rook.materialize() |> Map.merge(Ceph.materialize(config))
  end

  def materialize(%{} = config, :prometheus_operator), do: PrometheusOperator.materialize(config)
  def materialize(%{} = config, :prometheus), do: Prometheus.materialize(config)
  def materialize(%{} = config, :grafana), do: Grafana.materialize(config)
  def materialize(%{} = config, :alert_manager), do: Alertmanager.materialize(config)
  def materialize(%{} = config, :node_exporter), do: NodeExporter.materialize(config)
  def materialize(%{} = config, :kube_state_metrics), do: KubeStateMetrics.materialize(config)
  def materialize(%{} = config, :prometheus_stack), do: PrometheusStack.materialize(config)

  def materialize(%{} = config, :monitoring_api_server),
    do: MonitoringApiServer.materialize(config)

  def materialize(%{} = config, :monitoring_controller_manager),
    do: MonitoringControllerManager.materialize(config)

  def materialize(%{} = config, :monitoring_coredns), do: MonitoringCoredns.materialize(config)
  def materialize(%{} = config, :monitoring_etcd), do: MonitoringEtcd.materialize(config)

  def materialize(%{} = config, :monitoring_kube_proxy),
    do: MonitoringKubeProxy.materialize(config)

  def materialize(%{} = config, :monitoring_kubelet), do: MonitoringKubelet.materialize(config)

  def materialize(%{} = config, :monitoring_scheduler),
    do: MonitoringScheduler.materialize(config)

  def materialize(%{} = config, :loki), do: Loki.materialize(config)
  def materialize(%{} = config, :promtail), do: Promtail.materialize(config)

  def materialize(%{} = config, :data), do: Data.materialize(config)
  def materialize(%{} = config, :postgres_operator), do: PostgresOperator.materialize(config)
  def materialize(%{} = config, :database_public), do: Database.materialize_public(config)
  def materialize(%{} = config, :database_internal), do: Database.materialize_internal(config)
  def materialize(%{} = config, :redis), do: Redis.materialize(config)

  def materialize(%{} = config, :cert_manager), do: CertManager.materialize(config)
  def materialize(%{} = config, :keycloak), do: Keycloak.materialize(config)
  def materialize(%{} = config, :ory_hydra), do: OryHydra.materialize(config)

  def materialize(%{} = config, :gitea), do: Gitea.materialize(config)
  def materialize(%{} = config, :tekton), do: Tekton.materialize(config)
  def materialize(%{} = config, :tekton_dashboard), do: TektonDashboard.materialize(config)
  def materialize(%{} = config, :knative), do: KnativeOperator.materialize(config)
  def materialize(%{} = config, :knative_serving), do: KnativeServing.materialize(config)
  def materialize(%{} = config, :harbor), do: Harbor.materialize(config)

  def materialize(%{} = config, :istio), do: IstioBase.materialize(config)
  def materialize(%{} = config, :istio_istiod), do: IstioIstiod.materialize(config)
  def materialize(%{} = config, :kiali), do: Kiali.materialize(config)
  def materialize(%{} = config, :metallb), do: MetalLB.materialize(config)
  def materialize(%{} = config, :dev_metallb), do: DevMetalLB.materialize(config)

  def materialize(%{} = config, :battery), do: Battery.materialize(config)
  def materialize(%{} = config, :control_server), do: ControlServerResources.materialize(config)
  def materialize(%{} = config, :echo_server), do: EchoServer.materialize(config)

  def materialize(%{} = config, :ml), do: ML.Base.materialize(config)
  def materialize(%{} = config, :notebooks), do: Notebooks.materialize(config)

  def materialize(nil, _), do: %{}
end
