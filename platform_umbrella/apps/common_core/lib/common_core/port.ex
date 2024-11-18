defmodule CommonCore.Port do
  @moduledoc false
  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.Schema
  alias CommonCore.Protocol

  @required_fields ~w(name number)a

  batt_embedded_schema do
    field :name, :string
    field :number, :integer
    field :protocol, Protocol, default: :http2
  end

  def changeset(struct, params \\ %{}, opts \\ []) do
    struct
    |> Schema.schema_changeset(params, opts)
    |> downcase_fields([:name])
  end
end
