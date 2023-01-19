defmodule CommonCore.Postgres.PGInfraUser do
  use TypedEctoSchema
  import Ecto.Changeset
  import CommonCore.Postgres

  alias CommonCore.Defaults.RandomKeyChangeset

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :username, :string
    field :generated_key, :string
    field :roles, {:array, :string}, default: []
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:username, :generated_key, :roles])
    |> validate_required([:username, :roles])
    |> validate_pg_rolelist(:roles)
    |> RandomKeyChangeset.maybe_set_random(:generated_key)
  end
end
