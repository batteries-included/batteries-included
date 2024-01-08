defmodule CommonCore.Batteries.IstioGatewayConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :istio_gateway
  use TypedEctoSchema
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :proxy_image, :string, default: Defaults.Images.istio_proxy_image()

    type_field()
  end
end
