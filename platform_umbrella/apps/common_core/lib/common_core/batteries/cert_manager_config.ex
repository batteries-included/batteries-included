defmodule CommonCore.Batteries.CertManagerConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :cert_manager
  use TypedEctoSchema

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    type_field()
  end
end
