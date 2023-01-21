defmodule CommonCore.Batteries.OryKratosConfig do
  use TypedEctoSchema
  import Ecto.Changeset
  import CommonCore.Defaults.RandomKeyChangeset

  alias CommonCore.Defaults

  @required_fields ~w(replicas)a
  @optional_fields ~w(image secret_cipher secret_cookie secret_default)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.ory_kratos_image()
    field :dev, :boolean, default: true
    field :replicas, :integer, default: 1
    field :secret_cipher, :string, redact: true
    field :secret_cookie, :string, redact: true
    field :secret_default, :string, redact: true
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
    |> maybe_set_random(:secret_cipher, length: 32)
    |> maybe_set_random(:secret_cookie, length: 32)
    |> maybe_set_random(:secret_default)
    |> validate_required(@required_fields)
  end
end
