defmodule CommonCore.Batteries.RedisConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :redis
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :operator_image, :string, default: Defaults.Images.redis_operator_image()
    type_field()
  end
end
