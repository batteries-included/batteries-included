defmodule CommonCore.Batteries.IstioConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :istio do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.istio()

    defaultable_image_field :cni_image, image_id: :istio_cni
    defaultable_image_field :pilot_image, image_id: :istio_pilot
    defaultable_image_field :ztunnel_image, image_id: :istio_ztunnel
  end
end
