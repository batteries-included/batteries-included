defmodule CommonCore.Batteries.SystemBattery do
  use Ecto.Schema

  import Ecto.Changeset
  import PolymorphicEmbed

  alias CommonCore.Batteries.{
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
    MLCoreConfig,
    MetalLBConfig,
    MetalLBIPPoolConfig,
    NodeExporterConfig,
    PostgresOperatorConfig,
    RedisOperatorConfig,
    RookConfig
  }

  @possible_types [
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
    istio_csr: EmptyConfig,
    kiali: KialiConfig,
    knative_operator: KnativeOperatorConfig,
    knative_serving: KnativeServingConfig,
    kube_state_metrics: KubeStateMetricsConfig,
    metallb: MetalLBConfig,
    metallb_ip_pool: MetalLBIPPoolConfig,
    ml_core: MLCoreConfig,
    node_exporter: NodeExporterConfig,
    notebooks: EmptyConfig,
    postgres_operator: PostgresOperatorConfig,
    redis_operator: RedisOperatorConfig,
    redis: EmptyConfig,
    rook: RookConfig,
    cert_manager: EmptyConfig,
    trust_manager: EmptyConfig,
    battery_ca: EmptyConfig
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
    |> validate_required([:group, :type])
    |> cast_polymorphic_embed(:config)
  end

  def to_fresh_args(system_battery) do
    system_battery
    |> Map.from_struct()
    |> Map.drop([:__meta__, :__struct__])
    |> Map.update(:config, %{}, fn val ->
      val
      |> Map.put(:__type__, system_battery.type)
      |> Map.drop([:__meta__, :__struct__])
      |> Enum.filter(fn {_key, value} -> value != nil end)
      |> Map.new()
    end)
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Map.new()
  end
end
