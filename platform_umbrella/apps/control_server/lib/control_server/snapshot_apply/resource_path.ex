defmodule ControlServer.SnapshotApply.ResourcePath do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "resource_paths" do
    field :hash, :string
    field :path, :string
    field :resource_value, :map
    field :is_success, :boolean
    field :apply_result, :string

    belongs_to :kube_snapshot, ControlServer.SnapshotApply.KubeSnapshot

    timestamps()
  end

  @doc false
  def changeset(resource_path, attrs) do
    resource_path
    |> cast(attrs, [:path, :resource_value, :hash, :kube_snapshot_id, :is_success, :apply_result])
    |> validate_required([:path, :resource_value, :hash])
  end
end
