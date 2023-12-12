defmodule CommonCore.Batteries.IstioConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :istio
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.istio()
    defaultable_field :pilot_image, :string, default: Defaults.Images.istio_pilot_image()
    type_field()
  end
end
