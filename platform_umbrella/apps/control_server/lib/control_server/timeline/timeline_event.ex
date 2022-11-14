defmodule ControlServer.Timeline.TimelineEvent do
  use TypedEctoSchema
  import Ecto.Changeset
  import PolymorphicEmbed
  alias ControlServer.Timeline.BatteryInstall
  alias ControlServer.Timeline.Kube
  alias ControlServer.Timeline.NamedDatabase

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "timeline_events" do
    field :level, Ecto.Enum,
      values: [
        :info,
        :error
      ]

    polymorphic_embeds_one :payload,
      types: [
        battery_install: BatteryInstall,
        kube: Kube,
        named_database: NamedDatabase
      ],
      on_type_not_found: :raise,
      on_replace: :update

    timestamps()
  end

  @doc false
  def changeset(timeline_event, attrs) do
    timeline_event
    |> cast(attrs, [:level])
    |> cast_polymorphic_embed(:payload, required: true)
    |> validate_required([])
  end
end
