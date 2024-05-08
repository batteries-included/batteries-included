defmodule CommonCore.Batteries.TrustManagerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :trust_manager do
    defaultable_field :image, :string, default: Defaults.Images.trust_manager_image()
    defaultable_field :init_image, :string, default: Defaults.Images.trust_manager_init_image()
  end
end
