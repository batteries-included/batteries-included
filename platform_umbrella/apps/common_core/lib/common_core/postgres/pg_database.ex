defmodule CommonCore.Postgres.PGDatabase do
  @moduledoc false

  use CommonCore, :embedded_schema

  typed_embedded_schema do
    field :name, :string
    field :owner, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :owner])
    |> validate_required([:name, :owner])
  end
end
