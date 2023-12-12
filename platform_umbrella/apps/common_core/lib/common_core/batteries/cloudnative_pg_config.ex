defmodule CommonCore.Batteries.CloudnativePGConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :cloudnative_pg
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.cloudnative_pg_image()
    type_field()
  end
end
