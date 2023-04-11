defmodule CommonCore.Batteries.CertManagerConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [])
  end
end
