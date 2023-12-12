defmodule CommonCore.Batteries.IstioGatewayConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :istio_gateway
  use TypedEctoSchema

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    type_field()
  end
end
