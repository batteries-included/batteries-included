defmodule KubeResources.ConfigGenerator do
  @moduledoc """
  Given any SystemBattery this will extract the kubernetes configs for application to the cluster.
  """
  alias KubeExt.Builder, as: B
  alias KubeExt.Hashing

  alias KubeExt.SnapshotApply.StateSnapshot

  alias KubeRawResources.{Battery, IstioBase, IstioIstiod, PostgresOperator}

  alias KubeResources.{
    CertManager,
    ControlServerResources,
    Data,
    Database,
    EchoServer,
    Gitea,
    IstioGateway,
    Kiali,
    KnativeOperator,
    KnativeServing,
    ML,
    Notebooks,
    Redis,
    VirtualService,
    TektonOperator,
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

  @default_generator_mappings [
    alert_manager: [&Alertmanager.materialize/1],
    battery_core: [&Battery.materialize/1],
    cert_manager: [&CertManager.materialize/1],
    control_server: [&ControlServerResources.materialize/1],
    data: [&Data.materialize/1],
    database_internal: [&Database.materialize_internal/1],
    database_public: [&Database.materialize_public/1],
    dev_metallb: [&DevMetalLB.materialize/1],
    echo_server: [&EchoServer.materialize/1],
    gitea: [&Gitea.materialize/1],
    grafana: [&Grafana.materialize/1],
    harbor: [&Harbor.materialize/1],
    istio: [&IstioBase.materialize/1],
    istio_gateway: [&IstioGateway.materialize/1, &VirtualService.materialize/1],
    istio_istiod: [&IstioIstiod.materialize/1],
    kiali: [&Kiali.materialize/1],
    knative: [&KnativeOperator.materialize/1],
    knative_serving: [&KnativeServing.materialize/1],
    kube_state_metrics: [&KubeStateMetrics.materialize/1],
    loki: [&Loki.materialize/1],
    metallb: [&MetalLB.materialize/1],
    ml_core: [&ML.Base.materialize/1],
    monitoring_api_server: [&MonitoringApiServer.materialize/1],
    monitoring_controller_manager: [&MonitoringControllerManager.materialize/1],
    monitoring_coredns: [&MonitoringCoredns.materialize/1],
    monitoring_etcd: [&MonitoringEtcd.materialize/1],
    monitoring_kube_proxy: [&MonitoringKubeProxy.materialize/1],
    monitoring_kubelet: [&MonitoringKubelet.materialize/1],
    monitoring_scheduler: [&MonitoringScheduler.materialize/1],
    node_exporter: [&NodeExporter.materialize/1],
    notebooks: [&Notebooks.materialize/1],
    ory_hydra: [&OryHydra.materialize/1],
    postgres_operator: [&PostgresOperator.materialize/1],
    prometheus: [&Prometheus.materialize/1],
    prometheus_operator: [&PrometheusOperator.materialize/1],
    prometheus_stack: [&PrometheusStack.materialize/1],
    promtail: [&Promtail.materialize/1],
    redis: [&Redis.materialize/1],
    rook: [&Rook.materialize/1, &Ceph.materialize/1],
    tekton_operator: [&TektonOperator.materialize/1]
  ]

  @spec materialize(any()) :: map()
  def materialize(%StateSnapshot{} = state, mappings \\ @default_generator_mappings) do
    state.system_batteries
    |> Enum.map(fn system_battery ->
      generators = Keyword.fetch!(mappings, system_battery.type)
      materialize_system_battery(system_battery, generators)
    end)
    |> Enum.map(&Map.new/1)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  def default_generators, do: @default_generator_mappings

  def materialize_system_battery(system_battery, generators) do
    generators
    |> Enum.map(fn gen ->
      gen.(system_battery.config)
    end)
    |> Enum.reduce(%{}, &Map.merge/2)
    |> Enum.flat_map(&flatten/1)
    |> Enum.map(fn {key, resource} ->
      {
        Path.join("/#{Atom.to_string(system_battery.type)}", key),
        resource |> B.owner_label(system_battery.id) |> Hashing.decorate()
      }
    end)
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
end
