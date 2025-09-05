defmodule CommonCore.Timeline.NamedDatabase do
  @moduledoc false

  use CommonCore, :embedded_schema

  @possible_schema_types [
    :jupyter_notebook,
    :knative_service,
    :postgres_cluster,
    :redis_cluster,
    :ferret_service,
    :system_battery,
    :traditional_service,
    :model_instance,
    :issue
  ]

  def possible_schema_types, do: @possible_schema_types

  @required_fields ~w(action schema_type name entity_id)a

  batt_polymorphic_schema type: :named_database do
    # WAIT!
    # If you are changing here then change in EventCenter.Database
    field :action, Ecto.Enum, values: [:insert, :update, :delete, :multi]

    # WAIT!
    # If you are changing here then change in EventCenter.Database
    field :schema_type, Ecto.Enum, values: @possible_schema_types

    field :name, :string
    field :entity_id, CommonCore.Ecto.BatteryUUID
  end
end
