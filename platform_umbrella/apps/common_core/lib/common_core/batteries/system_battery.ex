defmodule CommonCore.Batteries.SystemBattery do
  @moduledoc false

  use CommonCore, :schema

  alias CommonCore.Batteries.AwsLoadBalancerControllerConfig
  alias CommonCore.Batteries.BatteryCAConfig
  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.CertManagerConfig
  alias CommonCore.Batteries.CloudnativePGConfig
  alias CommonCore.Batteries.FerretDBConfig
  alias CommonCore.Batteries.ForgejoConfig
  alias CommonCore.Batteries.GrafanaConfig
  alias CommonCore.Batteries.IstioConfig
  alias CommonCore.Batteries.IstioCSRConfig
  alias CommonCore.Batteries.IstioGatewayConfig
  alias CommonCore.Batteries.KarpenterConfig
  alias CommonCore.Batteries.KeycloakConfig
  alias CommonCore.Batteries.KialiConfig
  alias CommonCore.Batteries.KnativeConfig
  alias CommonCore.Batteries.KubeMonitoringConfig
  alias CommonCore.Batteries.LokiConfig
  alias CommonCore.Batteries.MetalLBConfig
  alias CommonCore.Batteries.NotebooksConfig
  alias CommonCore.Batteries.NvidiaDevicePluginConfig
  alias CommonCore.Batteries.OllamaConfig
  alias CommonCore.Batteries.PromtailConfig
  alias CommonCore.Batteries.RedisConfig
  alias CommonCore.Batteries.Smtp4devConfig
  alias CommonCore.Batteries.SSOConfig
  alias CommonCore.Batteries.StaleResourceCleanerConfig
  alias CommonCore.Batteries.TimelineConfig
  alias CommonCore.Batteries.TraditionalServicesConfig
  alias CommonCore.Batteries.TrivyOperatorConfig
  alias CommonCore.Batteries.TrustManagerConfig
  alias CommonCore.Batteries.VictoriaMetricsConfig
  alias CommonCore.Batteries.VMAgentConfig
  alias CommonCore.Ecto.PolymorphicType

  @derive {
    Flop.Schema,
    filterable: [],
    sortable: [:type, :group, :inserted_at, :updated_at],
    default_limit: 5,
    default_order: %{
      order_by: [:updated_at],
      order_directions: [:desc]
    }
  }

  @possible_types [
    aws_load_balancer_controller: AwsLoadBalancerControllerConfig,
    traditional_services: TraditionalServicesConfig,
    battery_ca: BatteryCAConfig,
    battery_core: BatteryCoreConfig,
    cert_manager: CertManagerConfig,
    cloudnative_pg: CloudnativePGConfig,
    forgejo: ForgejoConfig,
    grafana: GrafanaConfig,
    ferretdb: FerretDBConfig,
    istio: IstioConfig,
    istio_csr: IstioCSRConfig,
    istio_gateway: IstioGatewayConfig,
    keycloak: KeycloakConfig,
    kiali: KialiConfig,
    karpenter: KarpenterConfig,
    knative: KnativeConfig,
    kube_monitoring: KubeMonitoringConfig,
    loki: LokiConfig,
    metallb: MetalLBConfig,
    notebooks: NotebooksConfig,
    nvidia_device_plugin: NvidiaDevicePluginConfig,
    ollama: OllamaConfig,
    promtail: PromtailConfig,
    redis: RedisConfig,
    stale_resource_cleaner: StaleResourceCleanerConfig,
    smtp4dev: Smtp4devConfig,
    sso: SSOConfig,
    timeline: TimelineConfig,
    trivy_operator: TrivyOperatorConfig,
    trust_manager: TrustManagerConfig,
    victoria_metrics: VictoriaMetricsConfig,
    vm_agent: VMAgentConfig
  ]

  @possible_groups ~w(data devtools magic ai monitoring net_sec)a

  @required_fields ~w(group type config)a

  def possible_types, do: Keyword.keys(@possible_types)

  def for_type(type, possibles \\ @possible_types) do
    case Enum.find(possibles, fn {key, _} -> key == type end) do
      {_, config} -> config
      _ -> nil
    end
  end

  batt_schema "system_batteries" do
    field :group, Ecto.Enum, values: @possible_groups

    field :type, Ecto.Enum, values: Keyword.keys(@possible_types)

    field :config, PolymorphicType, mappings: @possible_types

    timestamps()
  end

  def to_fresh_args(%__MODULE__{} = system_battery) do
    system_battery
    |> Map.from_struct()
    |> Map.update!(:config, fn config -> Map.from_struct(config) end)
  end

  def to_fresh_args(%{} = sb_map), do: sb_map
end
