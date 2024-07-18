defmodule CommonCore.Port do
  @moduledoc false
  use CommonCore, :embedded_schema

  @required_fields ~w(name port)a

  @protocols [
    tcp: :tcp,
    udp: :udp,
    sctp: :sctp
  ]

  batt_embedded_schema do
    field :name, :string
    field :port, :integer
    field :protocol, Ecto.Enum, values: [:tcp, :udp, :sctp], default: :tcp
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> CommonCore.Ecto.Schema.schema_changeset(params)
    |> downcase_fields([:name])
  end

  def protocols, do: @protocols
end
