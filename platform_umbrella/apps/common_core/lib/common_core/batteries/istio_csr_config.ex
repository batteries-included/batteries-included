defmodule CommonCore.Batteries.IstioCSRConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :istio_csr
  use TypedEctoSchema

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    type_field()
  end
end
