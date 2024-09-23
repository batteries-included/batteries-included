defmodule CommonCore.Batteries.KeycloakConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:admin_password]}

  @required_fields ~w()a
  @read_only_fields ~w(admin_username admin_password)a

  batt_polymorphic_schema type: :keycloak do
    defaultable_image_field :image, image_id: :keycloak

    field :admin_username, :string, default: "batteryadmin"
    defaultable_field :log_level, :string, default: "info"
    defaultable_field :replicas, :integer, default: 1
    secret_field :admin_password
  end
end
