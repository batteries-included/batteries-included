defmodule ControlServer.SnapshotApply.KubeSnapshot do
  use TypedEctoSchema
  import Ecto.Changeset

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

  def next_status(%__MODULE__{status: status} = _kube_snapshot), do: do_next_status(status)

  defp do_next_status(status) do
    ControlServer.SnapshotApply.KubeSnapshot
    |> Ecto.Enum.values(:status)
    |> Enum.drop_while(fn s -> s != status end)
    |> Enum.drop(1)
    |> List.first(:error)
  end
end
