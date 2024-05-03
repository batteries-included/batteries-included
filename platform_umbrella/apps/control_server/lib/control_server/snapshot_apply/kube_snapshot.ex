defmodule ControlServer.SnapshotApply.KubeSnapshot do
  @moduledoc false

  use CommonCore, :schema

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
