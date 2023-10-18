defmodule CommonCore.Batteries.SystemBattery do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset
  import PolymorphicEmbed

  alias CommonCore.Batteries.BatteryCAConfig
  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.CertManagerConfig
  alias CommonCore.Batteries.CloudnativePGConfig
  alias CommonCore.Batteries.GiteaConfig
  alias CommonCore.Batteries.GrafanaConfig
  alias CommonCore.Batteries.IstioConfig
  alias CommonCore.Batteries.IstioCSRConfig
  alias CommonCore.Batteries.IstioGatewayConfig
  alias CommonCore.Batteries.KeycloakConfig
  alias CommonCore.Batteries.KialiConfig
  alias CommonCore.Batteries.KnativeOperatorConfig
  alias CommonCore.Batteries.KnativeServingConfig
  alias CommonCore.Batteries.KubeMonitoringConfig
  alias CommonCore.Batteries.LokiConfig
  alias CommonCore.Batteries.MetalLBConfig
  alias CommonCore.Batteries.NotebooksConfig
  alias CommonCore.Batteries.PromtailConfig
  alias CommonCore.Batteries.RedisConfig
  alias CommonCore.Batteries.RookConfig
  alias CommonCore.Batteries.Smtp4devConfig
  alias CommonCore.Batteries.SSOConfig
  alias CommonCore.Batteries.TimelineConfig
  alias CommonCore.Batteries.TrivyOperatorConfig
  alias CommonCore.Batteries.TrustManagerConfig
  alias CommonCore.Batteries.VictoriaMetricsConfig

  @possible_types [
    battery_ca: BatteryCAConfig,
    battery_core: BatteryCoreConfig,
    cert_manager: CertManagerConfig,
    cloudnative_pg: CloudnativePGConfig,
    gitea: GiteaConfig,
    grafana: GrafanaConfig,
    istio: IstioConfig,
    istio_csr: IstioCSRConfig,
    istio_gateway: IstioGatewayConfig,
    keycloak: KeycloakConfig,
    kiali: KialiConfig,
    knative_operator: KnativeOperatorConfig,
    knative_serving: KnativeServingConfig,
    kube_monitoring: KubeMonitoringConfig,
    loki: LokiConfig,
    metallb: MetalLBConfig,
    notebooks: NotebooksConfig,
    promtail: PromtailConfig,
    redis: RedisConfig,
    rook: RookConfig,
    smtp4dev: Smtp4devConfig,
    sso: SSOConfig,
    timeline: TimelineConfig,
    trivy_operator: TrivyOperatorConfig,
    trust_manager: TrustManagerConfig,
    victoria_metrics: VictoriaMetricsConfig
  ]

  def possible_types, do: Keyword.keys(@possible_types)

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "system_batteries" do
    field :group, Ecto.Enum,
      values: [
        :data,
        :devtools,
        :magic,
        :ml,
        :monitoring,
        :net_sec
      ]

    field :type, Ecto.Enum, values: Keyword.keys(@possible_types)

    polymorphic_embeds_one :config, types: @possible_types, on_replace: :update

    timestamps()
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: binary() | nil,
          group: (:data | :devtools | :magic | :ml | :monitoring | :net_sec) | nil,
          type: atom(),
          config: map(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @doc false
  def changeset(system_battery, attrs) do
    system_battery
    |> cast(attrs, [:group, :type])
    |> validate_required([:group, :type])
    |> cast_polymorphic_embed(:config)
  end

  def to_fresh_args(%__MODULE__{} = system_battery) do
    system_battery
    |> Map.from_struct()
    |> Map.update!(:config, fn config ->
      config
      |> Map.from_struct()
      |> Map.put_new(:__type__, system_battery.type)
    end)
  end

  def to_fresh_args(%{} = sb_map) do
    battery_type = Map.get_lazy(sb_map, :type, fn -> Map.fetch!(sb_map, "type") end)

    Map.update(sb_map, :config, %{"__type__" => battery_type}, fn config ->
      Map.put_new(config, "__type__", battery_type)
    end)
  end
end
