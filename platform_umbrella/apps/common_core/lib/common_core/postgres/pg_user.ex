defmodule CommonCore.Postgres.PGUser do
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :username, :string
    field :roles, {:array, :string}, default: []
  end

  def possible_roles,
    do: ~w(superuser inherit login nologin createrole createdb replication bypassrls)

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:username, :roles])
    |> validate_required([:username, :roles])
  end
end
