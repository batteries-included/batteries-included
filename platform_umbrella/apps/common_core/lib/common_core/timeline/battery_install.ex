defmodule CommonCore.Timeline.BatteryInstall do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Batteries.SystemBattery

  batt_polymorphic_schema type: :battery_install do
    field :battery_type, Ecto.Enum, values: SystemBattery.possible_types()
  end
end
