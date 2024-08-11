defmodule CommonCore.Postgres.PGPasswordVersion do
  @moduledoc false

  use CommonCore, :embedded_schema

  @required_fields ~w(username password)a

  batt_embedded_schema do
    field :version, :integer
    field :username, :string
    secret_field :password, length: 24
  end
end
