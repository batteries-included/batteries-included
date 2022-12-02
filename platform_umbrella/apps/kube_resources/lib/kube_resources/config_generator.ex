defmodule KubeResources.ConfigGenerator do
  @moduledoc """
  Given any SystemBattery this will extract the kubernetes configs for application to the cluster.
  """
  alias KubeExt.Builder, as: B
  alias KubeExt.Hashing

  alias KubeExt.SystemState.StateSummary

  alias KubeResources.{
    Battery,
    IstioBase,
    IstioIstiod,
    PostgresOperator,
    ControlServerResources,
    Data,
    DatabaseInternal,
    DatabasePublic,
    EchoServer,
    Gitea,
    IstioGateway,
    Kiali,
    KnativeOperator,
    KnativeServing,
    ML,
    Notebooks,
    Redis,
    RedisOperator,
    VirtualService,
    Harbor,
    Rook,
    CephFilesystems,
    CephClusters,
    PrometheusOperator,
    Prometheus,
    Grafana,
    Alertmanager,
    NodeExporter,
    KubeStateMetrics,
    Loki,
    Promtail,
    MonitoringApiServer,
    MonitoringCoredns,
    MonitoringKubelet,
    PrometheusStack,
    MetalLB,
    MetalLBIPPool
  }

  alias KubeResources.ControlServer, as: ControlServerResources

  require Logger

  @default_generator_mappings [
    alertmanager: [&Alertmanager.materialize/2],
    battery_core: [&Battery.materialize/2],
    control_server: [&ControlServerResources.materialize/2],
    data: [&Data.materialize/2],
    database_internal: [&DatabaseInternal.materialize/2],
    database_public: [&DatabasePublic.materialize/2],
    echo_server: [&EchoServer.materialize/2],
    gitea: [&Gitea.materialize/2],
    grafana: [&Grafana.materialize/2],
    harbor: [&Harbor.materialize/2],
    istio: [&IstioBase.materialize/2],
    istio_gateway: [&IstioGateway.materialize/2, &VirtualService.materialize/2],
    istio_istiod: [&IstioIstiod.materialize/2],
    kiali: [&Kiali.materialize/2],
    knative_operator: [&KnativeOperator.materialize/2],
    knative_serving: [&KnativeServing.materialize/2],
    kube_state_metrics: [&KubeStateMetrics.materialize/2],
    loki: [&Loki.materialize/2],
    metallb: [&MetalLB.materialize/2],
    metallb_ip_pool: [&MetalLBIPPool.materialize/2],
    ml_core: [&ML.Core.materialize/2],
    monitoring_api_server: [&MonitoringApiServer.materialize/2],
    monitoring_coredns: [&MonitoringCoredns.materialize/2],
    monitoring_kubelet: [&MonitoringKubelet.materialize/2],
    node_exporter: [&NodeExporter.materialize/2],
    notebooks: [&Notebooks.materialize/2],
    postgres_operator: [&PostgresOperator.materialize/2],
    prometheus: [&Prometheus.materialize/2],
    prometheus_operator: [&PrometheusOperator.materialize/2],
    prometheus_stack: [&PrometheusStack.materialize/2],
    promtail: [&Promtail.materialize/2],
    redis_operator: [&RedisOperator.materialize/2],
    redis: [&Redis.materialize/2],
    rook: [&Rook.materialize/2],
    ceph: [&CephFilesystems.materialize/2, &CephClusters.materialize/2]
  ]

  @spec materialize(StateSummary.t()) :: map()
  def materialize(%StateSummary{} = state),
    do: do_materialize(state, @default_generator_mappings)

  defp do_materialize(%StateSummary{} = state, mappings) do
    state.batteries
    |> Enum.map(fn system_battery ->
      generators = Keyword.fetch!(mappings, system_battery.type)
      materialize_system_battery(system_battery, state, generators)
    end)
    |> Enum.map(&Map.new/1)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  def default_generators, do: @default_generator_mappings

  def materialize_system_battery(system_battery, state, generators) do
    generators
    |> Enum.map(fn gen ->
      gen.(system_battery, state)
    end)
    |> Enum.reduce(%{}, &Map.merge/2)
    |> Enum.flat_map(&flatten/1)
    |> Enum.map(fn {key, resource} ->
      {
        Path.join("/#{Atom.to_string(system_battery.type)}", key),
        resource
        |> add_owner(system_battery)
        |> Hashing.decorate()
      }
    end)
  end

  defp add_owner(resource, %{id: id}), do: B.owner_label(resource, id)
  defp add_owner(resource, _), do: resource

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
