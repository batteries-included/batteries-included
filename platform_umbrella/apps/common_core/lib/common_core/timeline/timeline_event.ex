defmodule CommonCore.Timeline.TimelineEvent do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Timeline.BatteryInstall
  alias CommonCore.Timeline.Kube
  alias CommonCore.Timeline.NamedDatabase
  alias CommonCore.Util.PolymorphicType

  @possible_types [
    battery_install: BatteryInstall,
    kube: Kube,
    named_database: NamedDatabase
  ]

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "timeline_events" do
    field :type, Ecto.Enum, values: Keyword.keys(@possible_types)

    field :payload, PolymorphicType, mappings: @possible_types

    timestamps()
  end

  @doc false
  def changeset(timeline_event, attrs) do
    timeline_event
    |> cast(attrs, [:type, :payload])
    |> validate_required([:type, :payload])
  end
end
