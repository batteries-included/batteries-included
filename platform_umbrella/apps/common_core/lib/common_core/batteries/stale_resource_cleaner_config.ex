defmodule CommonCore.Batteries.StaleResourceCleanerConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :stale_resource_cleaner
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :delay, :integer, default: 900_000
    type_field()
  end
end
