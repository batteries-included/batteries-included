defmodule CommonCore.Batteries.LokiConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  @required_fields ~w()a

  batt_polymorphic_schema type: :loki do
    defaultable_image_field :image, image_id: :loki
    defaultable_field :replication_factor, :integer, default: 1
    defaultable_field :replicas, :integer, default: 1
  end

  def changeset(struct, params \\ %{}, opts \\ []) do
    struct
    |> CommonCore.Ecto.Schema.schema_changeset(params, opts)
    |> validate_number(:replication_factor, greater_than: 0, less_than: 99)
    |> validate_number(:replicas, greater_than: 0, less_than: 99)
  end
end
