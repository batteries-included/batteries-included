defmodule CommonCore.Batteries.IstioCSRConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :istio_csr do
    defaultable_image_field :image, image_id: :cert_manager_istio_csr
  end
end
