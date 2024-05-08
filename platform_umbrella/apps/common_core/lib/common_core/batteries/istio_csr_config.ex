defmodule CommonCore.Batteries.IstioCSRConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :istio_csr do
  end
end
