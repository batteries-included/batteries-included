defmodule CommonCore.Batteries.BatteryCAConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :battery_ca

  typed_embedded_schema do
    type_field()
  end
end
