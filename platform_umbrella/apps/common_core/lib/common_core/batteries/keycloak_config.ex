defmodule CommonCore.Batteries.KeycloakConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :keycloak
  use CommonCore.Util.DefaultableField

  import CommonCore.Util.EctoValidations
  import CommonCore.Util.PolymorphicTypeHelpers

  alias CommonCore.Defaults

  @required_fields ~w()a

  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.keycloak_image()
    defaultable_field :admin_username, :string, default: "batteryadmin"
    defaultable_field :log_level, :string, default: "info"
    defaultable_field :replicas, :integer, default: 1
    field :admin_password, :string
    type_field()
  end

  @impl Ecto.Type
  def cast(data) do
    data
    |> changeset(__MODULE__)
    |> maybe_set_random(:admin_password)
    |> validate_required(@required_fields)
    |> apply_changeset_if_valid()
  end
end
