defmodule KubeResources.ConfigGenerator do
  @moduledoc """
  Given any SystemBattery this will extract the kubernetes configs for application to the cluster.
  """
  alias KubeExt.Builder, as: B
  alias KubeExt.Hashing

  alias KubeExt.SystemState.StateSummary

  alias KubeResources.{
    BatteryCA,
    BatteryCore,
    CephClusters,
    CephFilesystems,
    CertManager,
    ControlServerResources,
    Data,
    DatabaseInternal,
    DatabasePublic,
    Gitea,
    Harbor,
    IstioBase,
    IstioCsr,
    IstioGateway,
    IstioIstiod,
    IstioMetrics,
    Kiali,
    KnativeOperator,
    KnativeServing,
    ML,
    MetalLB,
    MetalLBIPPool,
    Notebooks,
    PostgresOperator,
    Redis,
    RedisOperator,
    Rook,
    TrustManager
  }

  alias KubeResources.ControlServer, as: ControlServerResources

  require Logger

  @default_generator_mappings [
    battery_core: [&BatteryCore.materialize/2],
    battery_ca: [&BatteryCA.materialize/2],
    control_server: [&ControlServerResources.materialize/2],
    cert_manager: [&CertManager.materialize/2],
    trust_manager: [&TrustManager.materialize/2],
    data: [&Data.materialize/2],
    database_internal: [&DatabaseInternal.materialize/2],
    database_public: [&DatabasePublic.materialize/2],
    gitea: [&Gitea.materialize/2],
    harbor: [&Harbor.materialize/2],
    istio: [&IstioBase.materialize/2, &IstioIstiod.materialize/2, &IstioMetrics.materialize/2],
    istio_gateway: [&IstioGateway.materialize/2],
    istio_csr: [&IstioCsr.materialize/2],
    kiali: [&Kiali.materialize/2],
    knative_operator: [&KnativeOperator.materialize/2],
    knative_serving: [&KnativeServing.materialize/2],
    metallb: [&MetalLB.materialize/2],
    metallb_ip_pool: [&MetalLBIPPool.materialize/2],
    ml_core: [&ML.Core.materialize/2],
    notebooks: [&Notebooks.materialize/2],
    postgres_operator: [&PostgresOperator.materialize/2],
    redis_operator: [&RedisOperator.materialize/2],
    redis: [&Redis.materialize/2],
    rook: [&Rook.materialize/2, &CephFilesystems.materialize/2, &CephClusters.materialize/2]
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
    |> Enum.reject(&(&1 == nil))
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
    |> Map.new()
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
