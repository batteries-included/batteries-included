defmodule CommonCore.Batteries.IstioConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :istio do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.istio()
    defaultable_image_field :pilot_image, image_id: :istio_pilot
  end
end
