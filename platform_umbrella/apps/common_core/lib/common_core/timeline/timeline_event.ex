defmodule CommonCore.Timeline.TimelineEvent do
  @moduledoc false

  use CommonCore, :schema

  alias CommonCore.Ecto.PolymorphicType
  alias CommonCore.Timeline.BatteryInstall
  alias CommonCore.Timeline.Keycloak
  alias CommonCore.Timeline.Kube
  alias CommonCore.Timeline.NamedDatabase

  @possible_types [
    battery_install: BatteryInstall,
    keycloak: Keycloak,
    kube: Kube,
    named_database: NamedDatabase
  ]

  @required_fields ~w(type payload)a

  batt_schema "timeline_events" do
    field :type, Ecto.Enum, values: Keyword.keys(@possible_types)

    field :payload, PolymorphicType, mappings: @possible_types

    timestamps()
  end
end
