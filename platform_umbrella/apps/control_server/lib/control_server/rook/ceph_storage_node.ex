defmodule ControlServer.Rook.CephStorageNode do
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :name, :string
    field :device_filter, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :device_filter])
    |> validate_required([:name, :device_filter])
  end
end
