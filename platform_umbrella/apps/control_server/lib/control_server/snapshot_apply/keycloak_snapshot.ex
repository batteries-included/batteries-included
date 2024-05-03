defmodule ControlServer.SnapshotApply.KeycloakSnapshot do
  @moduledoc false

  use CommonCore, :schema

  typed_schema "keycloak_snapshots" do
    field :status, Ecto.Enum, values: [:creation, :generation, :applying, :ok, :error]

    has_many :keycloak_actions, ControlServer.SnapshotApply.KeycloakAction

    belongs_to :umbrella_snapshot,
               ControlServer.SnapshotApply.UmbrellaSnapshot

    timestamps()
  end

  @doc false
  def changeset(keycloak_snapshot, attrs) do
    keycloak_snapshot
    |> cast(attrs, [:status, :umbrella_snapshot_id])
    |> validate_required([:status])
  end
end
