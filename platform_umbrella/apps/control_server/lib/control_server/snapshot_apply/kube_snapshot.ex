defmodule ControlServer.SnapshotApply.KubeSnapshot do
  @moduledoc false

  use CommonCore, :schema

  @required_fields [:status]

  batt_schema "kube_snapshots" do
    field :status, Ecto.Enum,
      values: [:creation, :generation, :applying, :ok, :error],
      default: :creation

    has_many :resource_paths, ControlServer.SnapshotApply.ResourcePath

    belongs_to :umbrella_snapshot,
               ControlServer.SnapshotApply.UmbrellaSnapshot

    timestamps()
  end
end
