defmodule ControlServer.SnapshotApply.ResourcePath do
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "resource_paths" do
    field :path, :string
    field :resource_value, :map, redact: true

    field :hash, :string
    field :api_version, :string
    field :kind, :string
    field :name, :string

    field :namespace, :string
    field :is_success, :boolean
    field :apply_result, :string

    belongs_to :kube_snapshot, ControlServer.SnapshotApply.KubeSnapshot

    timestamps()
  end

  @doc false
  def changeset(resource_path, attrs) do
    resource_path
    |> cast(attrs, [
      :path,
      :resource_value,
      :hash,
      :kube_snapshot_id,
      :is_success,
      :apply_result,
      :api_version,
      :kind,
      :name,
      :namespace
    ])
    |> validate_required([:path, :resource_value, :hash, :kind, :api_version, :name])
  end
end
