defmodule CommonCore.Batteries.IstioGatewayConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :istio_gateway do
    defaultable_field :proxy_image, :string, default: Defaults.Images.istio_proxy_image()
  end
end
