defmodule CommonCore.Batteries.SsoConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  @required_fields ~w()a
  @optional_fields ~w(dev)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field(:dev, :boolean, default: true)
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
    |> validate_required(@required_fields)
  end
end
