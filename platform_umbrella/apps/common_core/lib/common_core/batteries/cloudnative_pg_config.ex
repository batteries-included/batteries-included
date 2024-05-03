defmodule CommonCore.Batteries.CloudnativePGConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :cloudnative_pg
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.cloudnative_pg_image()
    type_field()
  end
end
