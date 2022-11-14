defmodule ControlServer.Batteries.SystemBattery do
  use TypedEctoSchema
  import Ecto.Changeset
  import PolymorphicEmbed

  alias ControlServer.Batteries.MetalLBConfig
  alias ControlServer.Batteries.MLCoreConfig
  alias ControlServer.Batteries.IstioConfig
  alias ControlServer.Batteries.BatteryCoreConfig
  alias ControlServer.Batteries.EmptyConfig
  alias ControlServer.Batteries.DataConfig
  alias ControlServer.Batteries.KnativeServingConfig

  @possible_types [
    :alert_manager,
    :battery_core,
    :control_server,
    :data,
    :database_internal,
    :database_public,
    :dev_metallb,
    :echo_server,
    :gitea,
    :grafana,
    :harbor,
    :istio,
    :istio_gateway,
    :istio_istiod,
    :kiali,
    :knative,
    :knative_serving,
    :kube_state_metrics,
    :loki,
    :metallb,
    :ml_core,
    :monitoring_api_server,
    :monitoring_controller_manager,
    :monitoring_coredns,
    :monitoring_etcd,
    :monitoring_kube_proxy,
    :monitoring_kubelet,
    :monitoring_scheduler,
    :node_exporter,
    :notebooks,
    :ory_hydra,
    :postgres_operator,
    :prometheus,
    :prometheus_operator,
    :prometheus_stack,
    :promtail,
    :redis_operator,
    :redis,
    :rook,
    :ceph,
    :tekton_operator
  ]

  def possible_types, do: @possible_types

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "system_batteries" do
    field :group, Ecto.Enum,
      values: [
        :data,
        :devtools,
        :magic,
        :ml,
        :monitoring,
        :net_sec
      ]

    field :type, Ecto.Enum, values: @possible_types

    polymorphic_embeds_one :config,
      types: [
        empty: EmptyConfig,
        battery_core: BatteryCoreConfig,
        data: DataConfig,
        istio: IstioConfig,
        ml_core: MLCoreConfig,
        metallb: MetalLBConfig,
        knative_serving: KnativeServingConfig
      ],
      on_replace: :update

    timestamps()
  end

  @doc false
  def changeset(system_battery, attrs) do
    system_battery
    |> cast(attrs, [:group, :type])
    |> cast_polymorphic_embed(:config)
    |> validate_required([:group, :type])
  end
end
