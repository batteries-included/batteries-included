defmodule CommonCore.Batteries.IstioGatewayConfig do
  @moduledoc false
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
