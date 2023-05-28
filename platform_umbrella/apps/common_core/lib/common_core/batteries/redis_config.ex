defmodule CommonCore.Batteries.RedisConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :operator_image, :string, default: Defaults.Images.redis_operator_image()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:operator_image])
  end
end
