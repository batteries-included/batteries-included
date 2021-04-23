defmodule ControlServer.Services.BaseService do
  @moduledoc """
  BaseServices are the running service that customers
   will see as the thing they are interacting with.

  It's an entry point into generating kubernetes configs.

  %BaseService{} |> ConfigGenerator.materialize
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "base_services" do
    field :is_active, :boolean, default: false
    field :root_path, :string

    field :service_type, Ecto.Enum,
      values: [:prometheus, :log_aggregation, :storage, :postgres, :ingress]

    field :config, :map

    timestamps()
  end

  @doc false
  def changeset(base_service, attrs) do
    base_service
    |> cast(attrs, [:root_path, :is_active, :config, :service_type])
    |> validate_required([:root_path, :is_active, :config, :service_type])
  end
end
