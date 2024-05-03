defmodule CommonCore.Batteries.StaleResourceCleanerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :stale_resource_cleaner
  use CommonCore.Util.DefaultableField

  @required_fields ~w()a

  typed_embedded_schema do
    defaultable_field :delay, :integer, default: 900_000
    type_field()
  end
end
