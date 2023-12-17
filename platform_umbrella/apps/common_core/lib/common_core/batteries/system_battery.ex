defmodule CommonCore.Batteries.SystemBattery do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Batteries.BatteryCAConfig
  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.CertManagerConfig
  alias CommonCore.Batteries.CloudnativePGConfig
  alias CommonCore.Batteries.FerretDBConfig
  alias CommonCore.Batteries.GiteaConfig
  alias CommonCore.Batteries.GrafanaConfig
  alias CommonCore.Batteries.IstioConfig
  alias CommonCore.Batteries.IstioCSRConfig
  alias CommonCore.Batteries.IstioGatewayConfig
  alias CommonCore.Batteries.KeycloakConfig
  alias CommonCore.Batteries.KialiConfig
  alias CommonCore.Batteries.KnativeConfig
  alias CommonCore.Batteries.KubeMonitoringConfig
  alias CommonCore.Batteries.LokiConfig
  alias CommonCore.Batteries.MetalLBConfig
  alias CommonCore.Batteries.NotebooksConfig
  alias CommonCore.Batteries.PromtailConfig
  alias CommonCore.Batteries.RedisConfig
  alias CommonCore.Batteries.RookConfig
  alias CommonCore.Batteries.Smtp4devConfig
  alias CommonCore.Batteries.SSOConfig
  alias CommonCore.Batteries.StaleResourceCleanerConfig
  alias CommonCore.Batteries.TimelineConfig
  alias CommonCore.Batteries.TrivyOperatorConfig
  alias CommonCore.Batteries.TrustManagerConfig
  alias CommonCore.Batteries.VictoriaMetricsConfig
  alias CommonCore.Batteries.VMAgentConfig
  alias CommonCore.Batteries.VMClusterConfig
  alias CommonCore.Batteries.VMOperatorConfig
  alias CommonCore.Util.PolymorphicType

  @possible_types [
    battery_ca: BatteryCAConfig,
    battery_core: BatteryCoreConfig,
    cert_manager: CertManagerConfig,
    cloudnative_pg: CloudnativePGConfig,
    gitea: GiteaConfig,
    grafana: GrafanaConfig,
    ferretdb: FerretDBConfig,
    istio: IstioConfig,
    istio_csr: IstioCSRConfig,
    istio_gateway: IstioGatewayConfig,
    keycloak: KeycloakConfig,
    kiali: KialiConfig,
    knative: KnativeConfig,
    kube_monitoring: KubeMonitoringConfig,
    loki: LokiConfig,
    metallb: MetalLBConfig,
    notebooks: NotebooksConfig,
    promtail: PromtailConfig,
    redis: RedisConfig,
    rook: RookConfig,
    stale_resource_cleaner: StaleResourceCleanerConfig,
    smtp4dev: Smtp4devConfig,
    sso: SSOConfig,
    timeline: TimelineConfig,
    trivy_operator: TrivyOperatorConfig,
    trust_manager: TrustManagerConfig,
    victoria_metrics: VictoriaMetricsConfig,
    vm_operator: VMOperatorConfig,
    vm_agent: VMAgentConfig,
    vm_cluster: VMClusterConfig
  ]

  @possible_groups ~w(data devtools magic ml monitoring net_sec)a

  def possible_types, do: Keyword.keys(@possible_types)

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "system_batteries" do
    field :group, Ecto.Enum, values: @possible_groups

    field :type, Ecto.Enum, values: Keyword.keys(@possible_types)

    field :config, PolymorphicType, mappings: @possible_types

    timestamps()
  end

  @doc false
  def changeset(system_battery, attrs) do
    system_battery
    |> cast(attrs, [:group, :type, :config])
    |> validate_required([:group, :type])
  end

  def to_fresh_args(%__MODULE__{} = system_battery) do
    system_battery
    |> Map.from_struct()
    |> Map.update!(:config, fn config -> Map.from_struct(config) end)
  end

  def to_fresh_args(%{} = sb_map), do: sb_map
end
