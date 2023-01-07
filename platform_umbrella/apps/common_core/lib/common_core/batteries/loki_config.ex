defmodule CommonCore.Batteries.LokiConfig do
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.loki_image()
    field :replication_factor, :integer, default: 1
    field :replicas, :integer, default: 1
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:image, :replication_factor, :replicas])
    |> validate_number(:replication_factor, greater_than: 0, less_than: 99)
    |> validate_number(:replicas, greater_than: 0, less_than: 99)
  end
end
