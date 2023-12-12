defmodule CommonCore.Batteries.BatteryCAConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :battery_ca
  use TypedEctoSchema

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    type_field()
  end
end
