defmodule CommonCore.Timeline.BatteryInstall do
  @moduledoc false
  use TypedEctoSchema
  use CommonCore.Util.PolymorphicType, type: :battery_install

  alias CommonCore.Batteries.SystemBattery

  @primary_key false
  typed_embedded_schema do
    field :battery_type, Ecto.Enum, values: SystemBattery.possible_types()

    type_field()
  end
end
