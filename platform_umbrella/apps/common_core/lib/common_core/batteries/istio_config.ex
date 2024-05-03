defmodule CommonCore.Batteries.IstioConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :istio
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.istio()
    defaultable_field :pilot_image, :string, default: Defaults.Images.istio_pilot_image()
    type_field()
  end
end
