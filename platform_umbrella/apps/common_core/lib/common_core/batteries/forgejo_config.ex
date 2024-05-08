defmodule CommonCore.Batteries.ForgejoConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:admin_password]}

  alias CommonCore.Defaults

  @required_fields ~w()a

  batt_polymorphic_schema type: :forgejo do
    defaultable_field :image, :string, default: Defaults.Images.forgejo_image()
    defaultable_field :admin_username, :string, default: "battery-forgejo-admin"
    secret_field :admin_password
  end
end
