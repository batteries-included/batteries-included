defmodule CommonCore.Batteries.KeycloakConfig do
  use TypedEctoSchema
  import Ecto.Changeset
  alias CommonCore.Defaults.RandomKeyChangeset
  alias CommonCore.Defaults

  @required_fields ~w()a
  @optional_fields ~w(image admin_username admin_password)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.keycloak_image()
    field :admin_username, :string, default: "batteryadmin"
    field :admin_password, :string
  end

  @doc """
  Function for creating a change set that generates a KeyCloakConfig suitable for inserting into a database.

  This function should not be used with anything exposed to the
  user as it requires the secret_* fields to be exposed.
  """
  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> validate_required(@required_fields)
    |> RandomKeyChangeset.maybe_set_random(:admin_password)
  end
end
