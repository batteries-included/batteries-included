defmodule ControlServer.Batteries.SystemBattery do
  use Ecto.Schema

  import Ecto.Changeset
  import PolymorphicEmbed

  alias ControlServer.Batteries.{
    AlertmanagerConfig,
    BatteryCoreConfig,
    ControlServerConfig,
    DataConfig,
    EmptyConfig,
    GiteaConfig,
    GrafanaConfig,
    HarborConfig,
    IstioConfig,
    KialiConfig,
    KnativeOperatorConfig,
    KnativeServingConfig,
    KubeStateMetricsConfig,
    LokiConfig,
    MLCoreConfig,
    MetalLBConfig,
    MetalLBIPPoolConfig,
    NodeExporterConfig,
    PostgresOperatorConfig,
    PrometheusConfig,
    PrometheusOperatorConfig,
    PromtailConfig,
    RedisOperatorConfig,
    RookConfig
  }

  @possible_types [
    alertmanager: AlertmanagerConfig,
    battery_core: BatteryCoreConfig,
    control_server: ControlServerConfig,
    data: DataConfig,
    database_internal: EmptyConfig,
    database_public: EmptyConfig,
    gitea: GiteaConfig,
    grafana: GrafanaConfig,
    harbor: HarborConfig,
    istio: IstioConfig,
    istio_gateway: EmptyConfig,
    kiali: KialiConfig,
    knative_operator: KnativeOperatorConfig,
    knative_serving: KnativeServingConfig,
    kube_state_metrics: KubeStateMetricsConfig,
    loki: LokiConfig,
    metallb: MetalLBConfig,
    metallb_ip_pool: MetalLBIPPoolConfig,
    ml_core: MLCoreConfig,
    monitoring_api_server: EmptyConfig,
    monitoring_coredns: EmptyConfig,
    monitoring_kubelet: EmptyConfig,
    node_exporter: NodeExporterConfig,
    notebooks: EmptyConfig,
    postgres_operator: PostgresOperatorConfig,
    prometheus: PrometheusConfig,
    prometheus_operator: PrometheusOperatorConfig,
    prometheus_stack: EmptyConfig,
    promtail: PromtailConfig,
    redis_operator: RedisOperatorConfig,
    redis: EmptyConfig,
    rook: RookConfig,
    cert_manager: EmptyConfig
  ]

  def possible_types, do: Keyword.keys(@possible_types)

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "system_batteries" do
    field(:group, Ecto.Enum,
      values: [
        :data,
        :devtools,
        :magic,
        :ml,
        :monitoring,
        :net_sec
      ]
    )

    field(:type, Ecto.Enum, values: Keyword.keys(@possible_types))

    polymorphic_embeds_one(:config, types: @possible_types, on_replace: :update)

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
    |> cast_polymorphic_embed(:config)
    |> validate_required([:group, :type])
  end
end
