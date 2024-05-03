defmodule CommonCore.Postgres.PGUser do
  @moduledoc false

  use CommonCore, :embedded_schema

  import CommonCore.Postgres
  import CommonCore.Util.EctoValidations

  @required_fields ~w(username password roles)a
  @optional_fields ~w(credential_namespaces)a

  typed_embedded_schema do
    field :username, :string
    field :password, :string
    field :roles, {:array, :string}, default: []
    field :credential_namespaces, {:array, :string}, default: []
    field :position, :integer, virtual: true
  end

  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> maybe_set_random(:password, length: 24)
    |> validate_required(@required_fields)
    |> validate_pg_rolelist(:roles)
  end
end
