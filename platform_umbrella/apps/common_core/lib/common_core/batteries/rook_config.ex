defmodule CommonCore.Batteries.RookConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :rook
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.ceph_image()
    type_field()
  end
end
