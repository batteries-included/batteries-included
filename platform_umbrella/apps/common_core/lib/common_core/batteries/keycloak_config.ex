defmodule CommonCore.Batteries.KeycloakConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:admin_password]}

  alias CommonCore.Defaults

  @required_fields ~w()a

  batt_polymorphic_schema type: :keycloak do
    defaultable_field :image, :string, default: Defaults.Images.keycloak_image()
    defaultable_field :admin_username, :string, default: "batteryadmin"
    defaultable_field :log_level, :string, default: "info"
    defaultable_field :replicas, :integer, default: 1
    secret_field :admin_password
  end
end
