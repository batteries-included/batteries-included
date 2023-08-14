defmodule ControlServer.SnapshotApply.KubeSnapshot do
  use TypedEctoSchema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [],
    sortable: [:inserted_at, :id],
    default_limit: 12,
    default_order: %{
      order_by: [:inserted_at, :id],
      order_directions: [:desc, :desc]
    }
  }

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "kube_snapshots" do
    field :status, Ecto.Enum,
      values: [:creation, :generation, :applying, :ok, :error],
      default: :creation

    has_many :resource_paths, ControlServer.SnapshotApply.ResourcePath

    belongs_to :umbrella_snapshot,
               ControlServer.SnapshotApply.UmbrellaSnapshot

    timestamps()
  end

  @doc false
  def changeset(kube_snapshot, attrs) do
    kube_snapshot
    |> cast(attrs, [:status, :umbrella_snapshot_id])
    |> validate_required([:status])
  end
end
