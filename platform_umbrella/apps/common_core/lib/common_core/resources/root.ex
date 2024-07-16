defmodule CommonCore.Resources.RootResourceGenerator do
  @moduledoc """
  Given any SystemBattery this will extract the kubernetes configs for application to the cluster.
  """
  alias CommonCore.Resources.AwsLoadBalancerController
  alias CommonCore.Resources.BatteryAccess
  alias CommonCore.Resources.BatteryCA
  alias CommonCore.Resources.BatteryCore
  alias CommonCore.Resources.CertManager.Certificates
  alias CommonCore.Resources.CertManager.CertManager
  alias CommonCore.Resources.CertManager.TrustManager
  alias CommonCore.Resources.CloudnativePG
  alias CommonCore.Resources.CloudnativePGClusters
  alias CommonCore.Resources.CloudnativePGDashboards
  alias CommonCore.Resources.ControlServer, as: ControlServerResources
  alias CommonCore.Resources.FerretDB
  alias CommonCore.Resources.Forgejo
  alias CommonCore.Resources.Grafana
  alias CommonCore.Resources.Istio
  alias CommonCore.Resources.IstioCsr
  alias CommonCore.Resources.Istiod
  alias CommonCore.Resources.IstioIngress
  alias CommonCore.Resources.IstioMetrics
  alias CommonCore.Resources.IstioNamespace
  alias CommonCore.Resources.IstioReader
  alias CommonCore.Resources.IstioTelemetry
  alias CommonCore.Resources.Karpenter
  alias CommonCore.Resources.Keycloak
  alias CommonCore.Resources.Kiali
  alias CommonCore.Resources.KnativeMetrics
  alias CommonCore.Resources.KnativeNetIstio
  alias CommonCore.Resources.KnativeServices
  alias CommonCore.Resources.KnativeServing
  alias CommonCore.Resources.KnativeServingCRDs
  alias CommonCore.Resources.KubeDashboards
  alias CommonCore.Resources.KubeMonitoring
  alias CommonCore.Resources.KubeStateMetrics
  alias CommonCore.Resources.Loki
  alias CommonCore.Resources.MetalLB
  alias CommonCore.Resources.MetalLBPools
  alias CommonCore.Resources.MetricsServer
  alias CommonCore.Resources.NodeExporter
  alias CommonCore.Resources.Notebooks
  alias CommonCore.Resources.Promtail
  alias CommonCore.Resources.Redis
  alias CommonCore.Resources.RedisOperator
  alias CommonCore.Resources.Smtp4Dev
  alias CommonCore.Resources.SSO
  alias CommonCore.Resources.TextGenerationWebUI
  alias CommonCore.Resources.TraditionalServices
  alias CommonCore.Resources.TrivyOperator
  alias CommonCore.Resources.VMAgent
  alias CommonCore.Resources.VMCluster
  alias CommonCore.Resources.VMDashboards
  alias CommonCore.Resources.VMOperator
  alias CommonCore.StateSummary

  @default_generator_mappings [
    aws_load_balancer_controller: [AwsLoadBalancerController],
    traditional_services: [TraditionalServices],
    battery_ca: [BatteryCA],
    battery_core: [BatteryCore, ControlServerResources, BatteryAccess],
    cert_manager: [CertManager, Certificates],
    cloudnative_pg: [CloudnativePG, CloudnativePGClusters, CloudnativePGDashboards],
    forgejo: [Forgejo],
    grafana: [Grafana],
    istio: [IstioNamespace, Istio, Istiod, IstioReader, IstioTelemetry, IstioMetrics],
    istio_csr: [IstioCsr],
    istio_gateway: [IstioIngress],
    keycloak: [Keycloak],
    kiali: [Kiali],
    ferretdb: [FerretDB],
    knative: [KnativeServingCRDs, KnativeServing, KnativeNetIstio, KnativeServices, KnativeMetrics],
    kube_monitoring: [MetricsServer, KubeStateMetrics, NodeExporter, KubeMonitoring, KubeDashboards],
    karpenter: [Karpenter],
    loki: [Loki],
    metallb: [MetalLB, MetalLBPools],
    notebooks: [Notebooks],
    promtail: [Promtail],
    redis: [Redis, RedisOperator],
    smtp4dev: [Smtp4Dev],
    sso: [SSO],
    stale_resource_cleaner: [],
    text_generation_webui: [TextGenerationWebUI],
    timeline: [],
    trivy_operator: [TrivyOperator],
    trust_manager: [TrustManager],
    victoria_metrics: [VMDashboards],
    vm_agent: [VMAgent],
    vm_cluster: [VMCluster],
    vm_operator: [VMOperator]
  ]

  @spec materialize(StateSummary.t()) :: map()
  def materialize(%StateSummary{batteries: batteries} = state) do
    batteries
    |> Enum.map(fn %{type: type} = sb ->
      # Materialize the battery with the generators
      # We do all generators in one step rather than
      # flat map to allow for conflict resolution of paths.
      materialize_system_battery(
        sb,
        state,
        Keyword.fetch!(@default_generator_mappings, type)
      )
    end)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  def default_generators, do: @default_generator_mappings

  @doc """

  Given a single battery this will hangle all the generators f
  or that battery including renaming output to ensure there
  are no conflicts.

  For every generator in the list we will call the materialize method.

  The generators are expected to return a map of paths to resources.

  The values of that map could be a single resource
  (from `resource(:name, _bat, _state), do %{}`) or a list of
  resources (from `mulit_resource`). If it is a list of resources
  then we will flatten the list and append the index to the path. This is
  to ensure that we don't have any conflicts in the output.

  Then we append the battery type to the path to ensure that we don't have
  any conflicts between batteries.
  """
  def materialize_system_battery(system_battery, state, generators) do
    generators
    |> Enum.map(fn mod -> mod.materialize(system_battery, state) end)
    |> Enum.reduce(%{}, &Map.merge/2)
    |> Enum.flat_map(&flatten/1)
    |> Map.new(fn {key, resource} -> {Path.join(["/", Atom.to_string(system_battery.type), key]), resource} end)
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
