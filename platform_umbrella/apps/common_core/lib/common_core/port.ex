defmodule CommonCore.Port do
  @moduledoc false
  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.Schema

  @required_fields ~w(name number)a

  @protocols [
    HTTP: :http,
    HTTP2: :http2,
    TCP: :tcp
    # TODO: do we need this? If so, figure it out
    # UDP: :udp,
  ]

  batt_embedded_schema do
    field :name, :string
    field :number, :integer
    field :protocol, Ecto.Enum, values: Keyword.values(@protocols), default: :http2
  end

  def changeset(struct, params \\ %{}, opts \\ []) do
    struct
    |> Schema.schema_changeset(params, opts)
    |> downcase_fields([:name])
  end

  def protocols, do: @protocols

  def k8s_protocol(%{protocol: _}), do: "TCP"
end
