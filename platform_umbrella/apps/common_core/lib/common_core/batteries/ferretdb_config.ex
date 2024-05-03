defmodule CommonCore.Batteries.FerretDBConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :ferretdb
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :ferretdb_image, :string, default: Defaults.Images.ferretdb_image()
    type_field()
  end
end
