defmodule ControlServer.Deleted.DeletedResource do
  @moduledoc false

  use CommonCore, :schema

  @derive {
    Flop.Schema,
    filterable: [:name],
    sortable: [:name, :namespace, :kind, :updated_at],
    default_order: %{
      order_by: [:updated_at],
      order_directions: [:desc]
    }
  }

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
