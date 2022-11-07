defmodule ControlServer.Batteries.SystemBattery do
  use TypedEctoSchema
  import Ecto.Changeset

  @possible_types [
    :alert_manager,
    :battery_core,
    :cert_manager,
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

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "system_batteries" do
    field :config, :map, redact: true

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
    timestamps()
  end

  @doc false
  def changeset(system_battery, attrs) do
    system_battery
    |> cast(attrs, [:group, :type, :config])
    |> validate_required([:group, :type])
  end
end
