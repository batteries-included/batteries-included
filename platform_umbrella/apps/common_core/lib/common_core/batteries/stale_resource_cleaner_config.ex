defmodule CommonCore.Batteries.StaleResourceCleanerConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  @required_fields ~w()a
  @optional_fields ~w(delay)a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :delay, :integer, default: 900_000
  end

  @doc """
  Function for creating a change set that generates a config suitable for inserting into a database.

  This function should not be used with anything exposed to the
  user as it requires the secret_* fields to be exposed.
  """
  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> validate_required(@required_fields)
  end
end
