defmodule CommonCore.Batteries.PromtailConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :promtail do
    defaultable_image_field :image, image_id: :promtail
  end
end
