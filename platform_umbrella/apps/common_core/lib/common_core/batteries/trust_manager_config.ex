defmodule CommonCore.Batteries.TrustManagerConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :trust_manager
  use TypedEctoSchema

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    type_field()
  end
end
