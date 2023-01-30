defmodule KubeResources.ConfigGenerator do
  @moduledoc """
  Given any SystemBattery this will extract the kubernetes configs for application to the cluster.
  """
  alias CommonCore.SystemState.StateSummary

  alias KubeResources.{
    BatteryCA,
    BatteryCore,
    CephClusters,
    CephFilesystems,
    CertManager,
    ControlServerResources,
    Gitea,
    Grafana,
    Harbor,
    IstioBase,
    IstioCsr,
    IstioGateway,
    IstioIstiod,
    IstioMetrics,
    Kiali,
    KnativeOperator,
    KnativeServing,
    KubeMonitoring,
    KubeDashboards,
    KubeStateMetrics,
    Loki,
    MetalLB,
    MetalLBIPPool,
    NodeExporter,
    Notebooks,
    OryHydra,
    OryKratos,
    Postgres,
    PostgresOperator,
    Promtail,
    Redis,
    RedisOperator,
    Rook,
    Smtp4Dev,
    TrivyOperator,
    TrustManager,
    VMAgent,
    VMDashboards,
    VMCluster,
    VMOperator
  }

  alias KubeResources.ControlServer, as: ControlServerResources

  require Logger

  @default_generator_mappings [
    battery_ca: [&BatteryCA.materialize/2],
    battery_core: [&BatteryCore.materialize/2],
    cert_manager: [&CertManager.materialize/2],
    control_server: [&ControlServerResources.materialize/2],
    gitea: [&Gitea.materialize/2],
    grafana: [&Grafana.materialize/2],
    harbor: [&Harbor.materialize/2],
    istio: [&IstioBase.materialize/2, &IstioIstiod.materialize/2, &IstioMetrics.materialize/2],
    istio_csr: [&IstioCsr.materialize/2],
    istio_gateway: [&IstioGateway.materialize/2],
    kiali: [&Kiali.materialize/2],
    knative_operator: [&KnativeOperator.materialize/2],
    knative_serving: [&KnativeServing.materialize/2],
    kube_monitoring: [&KubeMonitoring.materialize/2, &KubeDashboards.materialize/2],
    kube_state_metrics: [&KubeStateMetrics.materialize/2],
    loki: [&Loki.materialize/2],
    metallb: [&MetalLB.materialize/2],
    metallb_ip_pool: [&MetalLBIPPool.materialize/2],
    node_exporter: [&NodeExporter.materialize/2],
    notebooks: [&Notebooks.materialize/2],
    postgres: [&Postgres.materialize/2, &PostgresOperator.materialize/2],
    promtail: [&Promtail.materialize/2],
    redis: [&Redis.materialize/2, &RedisOperator.materialize/2],
    rook: [&Rook.materialize/2, &CephFilesystems.materialize/2, &CephClusters.materialize/2],
    smtp4dev: [&Smtp4Dev.materialize/2],
    sso: [&OryKratos.materialize/2, &OryHydra.materialize/2],
    trivy_operator: [&TrivyOperator.materialize/2],
    trust_manager: [&TrustManager.materialize/2],
    victoria_metrics: [
      &VMOperator.materialize/2,
      &VMCluster.materialize/2,
      &VMAgent.materialize/2,
      &VMDashboards.materialize/2
    ]
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
      }
    end)
    |> Map.new()
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
