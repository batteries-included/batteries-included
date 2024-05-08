defmodule CommonCore.Batteries.IstioConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :istio do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.istio()
    defaultable_field :pilot_image, :string, default: Defaults.Images.istio_pilot_image()
  end
end
