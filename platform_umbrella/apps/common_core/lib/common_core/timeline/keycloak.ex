defmodule CommonCore.Timeline.Keycloak do
  @moduledoc false

  use CommonCore, :embedded_schema

  @possible_actions ~w(create_user reset_user_password)a

  batt_polymorphic_schema type: :keycloak do
    field :action, Ecto.Enum, values: @possible_actions
    field :entity_id, CommonCore.Ecto.BatteryUUID
    field :realm, :string
  end
end
