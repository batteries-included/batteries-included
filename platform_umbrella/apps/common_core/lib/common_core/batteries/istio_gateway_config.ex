defmodule CommonCore.Batteries.IstioGatewayConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :istio_gateway do
    defaultable_image_field :proxy_image, image_id: :istio_proxy
  end
end
