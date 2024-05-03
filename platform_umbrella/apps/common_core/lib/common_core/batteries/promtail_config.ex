defmodule CommonCore.Batteries.PromtailConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :promtail
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.promtail_image()
    type_field()
  end
end
