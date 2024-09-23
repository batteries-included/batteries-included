defmodule CommonCore.Batteries.ForgejoConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:admin_password]}

  @required_fields ~w()a
  @read_only_fields ~w(admin_username admin_password)a

  batt_polymorphic_schema type: :forgejo do
    defaultable_image_field :image, image_id: :forgejo
    defaultable_field :admin_username, :string, default: "battery-forgejo-admin"
    secret_field :admin_password
  end
end
