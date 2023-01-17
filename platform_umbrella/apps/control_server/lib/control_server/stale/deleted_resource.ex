defmodule ControlServer.Stale.DeletedResource do
  use TypedEctoSchema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "deleted_resources" do
    field :hash, :string
    field :name, :string
    field :namespace, :string
    field :kind, Ecto.Enum, values: CommonCore.ApiVersionKind.all_known()
    field :been_undeleted, :boolean, default: false

    belongs_to :content_addressable_resource,
               ControlServer.ContentAddressable.ContentAddressableResource

    timestamps()
  end

  @doc false
  def changeset(deleted_resource, attrs) do
    deleted_resource
    |> cast(attrs, [
      :kind,
      :name,
      :namespace,
      :hash,
      :content_addressable_resource_id,
      :been_undeleted
    ])
    |> validate_required([
      :kind,
      :name,
      :namespace,
      :hash,
      :content_addressable_resource_id,
      :been_undeleted
    ])
  end
end
