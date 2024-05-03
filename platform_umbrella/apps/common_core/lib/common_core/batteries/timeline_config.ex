defmodule CommonCore.Batteries.TimelineConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :timeline

  typed_embedded_schema do
    type_field()
  end
end
