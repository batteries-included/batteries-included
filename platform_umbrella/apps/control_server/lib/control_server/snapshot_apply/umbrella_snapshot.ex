defmodule ControlServer.SnapshotApply.UmbrellaSnapshot do
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  typed_schema "umbrella_snapshots" do
    has_one :kube_snapshot, ControlServer.SnapshotApply.KubeSnapshot
    has_one :keycloak_snapshot, ControlServer.SnapshotApply.KeycloakSnapshot

    timestamps()
  end

  @doc false
  def changeset(umbrella_snapshot, attrs) do
    umbrella_snapshot
    |> cast(attrs, [])
    |> validate_required([])
  end
end
