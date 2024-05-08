defmodule CommonCore.Batteries.BatteryCAConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :battery_ca do
  end
end
