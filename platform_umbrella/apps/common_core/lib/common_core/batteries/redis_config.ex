defmodule CommonCore.Batteries.RedisConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :redis do
    defaultable_image_field :operator_image, image_id: :redis_operator
    defaultable_image_field :redis_image, image_id: :redis
    defaultable_image_field :exporter_image, image_id: :redis_exporter
  end
end
