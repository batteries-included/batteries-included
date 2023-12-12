defmodule CommonCore.Batteries.PromtailConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :promtail
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.promtail_image()
    type_field()
  end
end
