defmodule CommonCore.Batteries.RedisConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :redis do
    defaultable_field :operator_image, :string, default: Defaults.Images.redis_operator_image()
    defaultable_field :redis_image, :string, default: Defaults.Images.redis_image()
    defaultable_field :exporter_image, :string, default: Defaults.Images.redis_exporter_image()
  end
end
