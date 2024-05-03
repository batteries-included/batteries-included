defmodule CommonCore.Timeline.TimelineEvent do
  @moduledoc false

  use CommonCore, :schema

  alias CommonCore.Timeline.BatteryInstall
  alias CommonCore.Timeline.Kube
  alias CommonCore.Timeline.NamedDatabase
  alias CommonCore.Util.PolymorphicType

  @possible_types [
    battery_install: BatteryInstall,
    kube: Kube,
    named_database: NamedDatabase
  ]

  @required_fields ~w(type payload)a
  @optional_fields ~w()a

  typed_schema "timeline_events" do
    field :type, Ecto.Enum, values: Keyword.keys(@possible_types)

    field :payload, PolymorphicType, mappings: @possible_types

    timestamps()
  end

  @doc false
  def changeset(timeline_event, attrs) do
    fields = Enum.concat(@required_fields, @optional_fields)

    timeline_event
    |> cast(attrs, fields)
    |> validate_required(@required_fields)
  end
end
