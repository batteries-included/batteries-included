defmodule ControlServer.Deleted.DeletedResource do
  @moduledoc false

  use CommonCore, :schema

  @required_fields ~w(kind name namespace hash document_id been_undeleted)a

  batt_schema "deleted_resources" do
    field :hash, :string
    field :name, :string
    field :namespace, :string
    field :kind, Ecto.Enum, values: CommonCore.ApiVersionKind.all_known()
    field :been_undeleted, :boolean, default: false

    belongs_to :document,
               ControlServer.ContentAddressable.Document

    timestamps()
  end
end
