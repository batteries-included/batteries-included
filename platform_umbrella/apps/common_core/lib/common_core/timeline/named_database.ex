defmodule CommonCore.Timeline.NamedDatabase do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :named_database

  @possible_schema_types [
    :jupyter_notebook,
    :knative_service,
    :postgres_cluster,
    :redis_cluster,
    :ferret_service,
    :system_battery,
    :backend_service
  ]

  def possible_schema_types, do: @possible_schema_types

  typed_embedded_schema do
    # WAIT!
    # If you are changing here then change in EventCenter.Database
    field :action, Ecto.Enum, values: [:insert, :update, :delete, :multi]

    # WAIT!
    # If you are changing here then change in EventCenter.Database
    field :schema_type, Ecto.Enum, values: @possible_schema_types

    field :name, :string
    field :entity_id, :binary_id

    type_field()
  end
end
