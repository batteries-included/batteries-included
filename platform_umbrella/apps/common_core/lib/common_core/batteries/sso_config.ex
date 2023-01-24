defmodule CommonCore.Batteries.SsoConfig do
  use TypedEctoSchema
  import Ecto.Changeset
  import CommonCore.Defaults.RandomKeyChangeset

  alias CommonCore.Defaults

  @required_fields ~w(hydra_secret_system hydra_secret_cookie kratos_secret_cipher kratos_secret_cookie kratos_secret_default)a
  @optional_fields ~w(dev hydra_image hydra_maester_image hydra_replicas kratos_image kratos_replicas)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:dev, :boolean, default: true)

    # Hydra
    field(:hydra_image, :string, default: Defaults.Images.ory_hydra_image())
    field(:hydra_maester_image, :string, default: Defaults.Images.ory_hydra_maester_image())
    field(:hydra_replicas, :integer, default: 1)
    field(:hydra_secret_system, :string, redact: true)
    field(:hydra_secret_cookie, :string, redact: true)

    # Kratos
    field(:kratos_image, :string, default: Defaults.Images.ory_kratos_image())
    field(:kratos_replicas, :integer, default: 1)
    field(:kratos_secret_cipher, :string, redact: true)
    field(:kratos_secret_cookie, :string, redact: true)
    field(:kratos_secret_default, :string, redact: true)
  end

  @doc """
  Function for creating a change set that generates a OryKratosConfig suitable for inserting into a database.

  This function should not be used with anything exposed to the
  use as it requires the secret_* fields to be exposed.
  """
  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> maybe_set_random(:hydra_secret_system, length: 32)
    |> maybe_set_random(:hydra_secret_cookie, length: 32)
    |> maybe_set_random(:kratos_secret_cipher, length: 32)
    |> maybe_set_random(:kratos_secret_cookie, length: 32)
    |> maybe_set_random(:kratos_secret_default)
    |> validate_required(@required_fields)
  end
end
