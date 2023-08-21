defmodule ControlServer.SnapshotApply.ResourcePath do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @required_fields [:path, :hash, :type, :name]
  @optional_fields [
    :kube_snapshot_id,
    :document_id,
    :is_success,
    :apply_result,
    :namespace
  ]

  typed_schema "resource_paths" do
    field :path, :string

    field :hash, :string

    field :type, Ecto.Enum, values: CommonCore.ApiVersionKind.all_known()

    field :name, :string
    field :namespace, :string

    field :is_success, :boolean
    field :apply_result, :string

    belongs_to :kube_snapshot, ControlServer.SnapshotApply.KubeSnapshot

    belongs_to :document,
               ControlServer.ContentAddressable.Document

    timestamps()
  end

  @doc false
  def changeset(resource_path, attrs) do
    resource_path
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
