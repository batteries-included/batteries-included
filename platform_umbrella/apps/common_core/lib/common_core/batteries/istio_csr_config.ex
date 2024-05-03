defmodule CommonCore.Batteries.IstioCSRConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :istio_csr

  typed_embedded_schema do
    type_field()
  end
end
