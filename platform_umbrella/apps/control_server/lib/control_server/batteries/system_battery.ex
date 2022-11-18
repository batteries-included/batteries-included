defmodule ControlServer.Batteries.SystemBattery do
  use Ecto.Schema

  import Ecto.Changeset
  import PolymorphicEmbed

  alias ControlServer.Batteries.AlertmanagerConfig
  alias ControlServer.Batteries.BatteryCoreConfig
  alias ControlServer.Batteries.CephConfig
  alias ControlServer.Batteries.ControlServerConfig
  alias ControlServer.Batteries.DataConfig
  alias ControlServer.Batteries.EmptyConfig
  alias ControlServer.Batteries.GiteaConfig
  alias ControlServer.Batteries.GrafanaConfig
  alias ControlServer.Batteries.HarborConfig
  alias ControlServer.Batteries.IstioConfig
  alias ControlServer.Batteries.IstioIstiodConfig
  alias ControlServer.Batteries.KialiConfig
  alias ControlServer.Batteries.KnativeOperatorConfig
  alias ControlServer.Batteries.KnativeServingConfig
  alias ControlServer.Batteries.KubeStateMetricsConfig
  alias ControlServer.Batteries.LokiConfig
  alias ControlServer.Batteries.MLCoreConfig
  alias ControlServer.Batteries.MetalLBConfig
  alias ControlServer.Batteries.MetalLBIPPoolConfig
  alias ControlServer.Batteries.NodeExporterConfig
  alias ControlServer.Batteries.PostgresOperatorConfig
  alias ControlServer.Batteries.PrometheusConfig
  alias ControlServer.Batteries.PrometheusOperatorConfig
  alias ControlServer.Batteries.PromtailConfig
  alias ControlServer.Batteries.RedisOperatorConfig

  @possible_types [
    alertmanager: AlertmanagerConfig,
    battery_core: BatteryCoreConfig,
    control_server: ControlServerConfig,
    data: DataConfig,
    database_internal: EmptyConfig,
    database_public: EmptyConfig,
    echo_server: EmptyConfig,
    gitea: GiteaConfig,
    grafana: GrafanaConfig,
    harbor: HarborConfig,
    istio: IstioConfig,
    istio_gateway: EmptyConfig,
    istio_istiod: IstioIstiodConfig,
    kiali: KialiConfig,
    knative_operator: KnativeOperatorConfig,
    knative_serving: KnativeServingConfig,
    kube_state_metrics: KubeStateMetricsConfig,
    loki: LokiConfig,
    metallb: MetalLBConfig,
    metallb_ip_pool: MetalLBIPPoolConfig,
    ml_core: MLCoreConfig,
    monitoring_api_server: EmptyConfig,
    monitoring_controller_manager: EmptyConfig,
    monitoring_coredns: EmptyConfig,
    monitoring_etcd: EmptyConfig,
    monitoring_kube_proxy: EmptyConfig,
    monitoring_kubelet: EmptyConfig,
    monitoring_scheduler: EmptyConfig,
    node_exporter: NodeExporterConfig,
    notebooks: EmptyConfig,
    postgres_operator: PostgresOperatorConfig,
    prometheus: PrometheusConfig,
    prometheus_operator: PrometheusOperatorConfig,
    prometheus_stack: EmptyConfig,
    promtail: PromtailConfig,
    redis_operator: RedisOperatorConfig,
    redis: EmptyConfig,
    rook: EmptyConfig,
    ceph: CephConfig
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
