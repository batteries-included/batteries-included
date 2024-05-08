defmodule CommonCore.Batteries.RedisConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :redis do
    defaultable_field :operator_image, :string, default: Defaults.Images.redis_operator_image()
  end
end
