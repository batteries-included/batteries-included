defmodule CommonCore.Batteries.TimelineConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :timeline
  use TypedEctoSchema

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    type_field()
  end
end
