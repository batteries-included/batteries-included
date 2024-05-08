defmodule ControlServer.SnapshotApply.KeycloakSnapshot do
  @moduledoc false

  use CommonCore, :schema

  @required_fields [:status]

  batt_schema "keycloak_snapshots" do
    field :status, Ecto.Enum, values: [:creation, :generation, :applying, :ok, :error]

    has_many :keycloak_actions, ControlServer.SnapshotApply.KeycloakAction

    belongs_to :umbrella_snapshot,
               ControlServer.SnapshotApply.UmbrellaSnapshot

    timestamps()
  end
end
