defmodule ControlServer.Timeline.BatteryInstall do
  use TypedEctoSchema
  import Ecto.Changeset
  alias ControlServer.Batteries.SystemBattery

  @primary_key false
  typed_embedded_schema do
    field :type, Ecto.Enum, values: SystemBattery.possible_types()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:type])
    |> validate_required([:type])
  end
end
