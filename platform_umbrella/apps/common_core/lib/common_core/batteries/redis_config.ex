defmodule CommonCore.Batteries.RedisConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :redis
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :operator_image, :string, default: Defaults.Images.redis_operator_image()
    type_field()
  end
end
