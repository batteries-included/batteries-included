defmodule CommonCore.Postgres.PGInfraUser do
  use TypedEctoSchema
  import Ecto.Changeset
  import CommonCore.Postgres

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
    |> maybe_add_random_generated_key()
  end

  defp maybe_add_random_generated_key(changeset) do
    generated_key = get_field(changeset, :generated_key)

    case generated_key do
      nil ->
        put_change(changeset, :generated_key, CommonCore.Defaults.random_key_string(128))

      _ ->
        changeset
    end
  end
end
