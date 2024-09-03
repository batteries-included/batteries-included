defmodule CommonCore.Batteries.TrustManagerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :trust_manager do
    defaultable_image_field :image, image_id: :trust_manager
    defaultable_image_field :init_image, image_id: :trust_manager_init
  end
end
