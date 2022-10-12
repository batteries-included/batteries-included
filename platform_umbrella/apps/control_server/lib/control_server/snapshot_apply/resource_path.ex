defmodule ControlServer.SnapshotApply.ResourcePath do
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "resource_paths" do
    field :path, :string

    field :hash, :string

    field :type, Ecto.Enum, values: KubeExt.ApiVersionKind.all_known()

    field :name, :string
    field :namespace, :string

    field :is_success, :boolean
    field :apply_result, :string

    belongs_to :kube_snapshot, ControlServer.SnapshotApply.KubeSnapshot

    belongs_to :content_addressable_resource,
               ControlServer.SnapshotApply.ContentAddressableResource

    timestamps()
  end

  @doc false
  def changeset(resource_path, attrs) do
    resource_path
    |> cast(attrs, [
      :path,
      :hash,
      :kube_snapshot_id,
      :content_addressable_resource_id,
      :is_success,
      :apply_result,
      :type,
      :name,
      :namespace
    ])
    |> validate_required([:path, :hash, :type, :name])
  end
end
