defmodule CommonCore.Timeline.TimelineEvent do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset
  import PolymorphicEmbed

  alias CommonCore.Timeline.BatteryInstall
  alias CommonCore.Timeline.Kube
  alias CommonCore.Timeline.NamedDatabase

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "timeline_events" do
    field(:level, Ecto.Enum,
      values: [
        :info,
        :error
      ]
    )

    polymorphic_embeds_one(:payload,
      types: [
        battery_install: BatteryInstall,
        kube: Kube,
        named_database: NamedDatabase
      ],
      on_type_not_found: :raise,
      on_replace: :update
    )

    timestamps()
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: binary() | nil,
          level: (:info | :error) | nil,
          payload: BatteryInstall.t() | Kube.t() | NamedDatabase.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @doc false
  def changeset(timeline_event, attrs) do
    timeline_event
    |> cast(attrs, [:level])
    |> cast_polymorphic_embed(:payload, required: true)
    |> validate_required([])
  end
end
