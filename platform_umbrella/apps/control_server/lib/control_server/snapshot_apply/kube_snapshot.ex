defmodule ControlServer.SnapshotApply.KubeSnapshot do
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "kube_snapshots" do
    field :status, Ecto.Enum,
      values: [:creation, :generation, :applying, :ok, :error],
      default: :creation

    has_many :resource_paths, ControlServer.SnapshotApply.ResourcePath

    timestamps()
  end

  @doc false
  def changeset(kube_snapshot, attrs) do
    kube_snapshot
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
