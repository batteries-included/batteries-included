defmodule CommonCore.Postgres.PGDatabase do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_embedded_schema do
    field :name, :string
    field :owner, :string
  end
end
