defmodule ControlServer.Services.BaseService do
  @moduledoc """
  BaseServices are the running service that customers
   will see as the thing they are interacting with.

  It's an entry point into generating kubernetes configs.

  %BaseService{} |> ConfigGenerator.materialize
  """
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "base_services" do
    field :root_path, :string

    field :service_type, Ecto.Enum,
      values: [
        :prometheus_operator,
        :prometheus,
        :grafana,
        :alert_manager,
        :kube_monitoring,
        :cert_manager,
        :devtools,
        :knative,
        :github_runner,
        :database,
        :database_public,
        :database_internal,
        :istio,
        :kong,
        :nginx,
        :ml,
        :notebooks,
        :battery,
        :echo_server,
        :control_server
      ]

    field :config, :map

    timestamps()
  end

  @doc false
  def changeset(base_service, attrs) do
    base_service
    |> cast(attrs, [:root_path, :config, :service_type])
    |> validate_required([:root_path, :config, :service_type])
  end
end
