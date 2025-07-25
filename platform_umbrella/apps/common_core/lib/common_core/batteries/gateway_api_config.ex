defmodule CommonCore.Batteries.GatewayAPIConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :gateway_api do
  end
end
