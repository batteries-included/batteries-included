defmodule CommonCore.Batteries.IstioGatewayConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :istio_gateway
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :proxy_image, :string, default: Defaults.Images.istio_proxy_image()

    type_field()
  end
end
