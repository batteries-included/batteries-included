defmodule ControlServer.Deleted.DeletedResource do
  @moduledoc false

  use CommonCore, :schema

  typed_schema "deleted_resources" do
    field :hash, :string
    field :name, :string
    field :namespace, :string
    field :kind, Ecto.Enum, values: CommonCore.ApiVersionKind.all_known()
    field :been_undeleted, :boolean, default: false

    belongs_to :document,
               ControlServer.ContentAddressable.Document

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
      :document_id,
      :been_undeleted
    ])
    |> validate_required([
      :kind,
      :name,
      :namespace,
      :hash,
      :document_id,
      :been_undeleted
    ])
  end
end
