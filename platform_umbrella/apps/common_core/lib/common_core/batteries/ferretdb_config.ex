defmodule CommonCore.Batteries.FerretDBConfig do
  @moduledoc false

  use CommonCore.Util.PolymorphicType, type: :ferretdb
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :ferretdb_image, :string, default: Defaults.Images.ferretdb_image()
    type_field()
  end
end
