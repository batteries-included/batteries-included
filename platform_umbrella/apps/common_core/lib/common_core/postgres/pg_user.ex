defmodule CommonCore.Postgres.PGUser do
  @moduledoc false

  use CommonCore, :embedded_schema

  import CommonCore.Postgres

  @required_fields ~w(username roles)a

  batt_embedded_schema do
    field :username, :string
    field :roles, {:array, :string}, default: []
    field :credential_namespaces, {:array, :string}, default: []
    field :position, :integer, virtual: true
  end

  def changeset(struct, params \\ %{}, opts \\ []) do
    struct
    |> CommonCore.Ecto.Schema.schema_changeset(params, opts)
    |> validate_pg_rolelist(:roles)
  end
end
