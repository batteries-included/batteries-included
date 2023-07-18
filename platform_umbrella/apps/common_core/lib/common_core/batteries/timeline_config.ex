defmodule CommonCore.Batteries.TimelineConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  @optional_fields []
  @required_fields []

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, @optional_fields ++ @required_fields)
  end
end
