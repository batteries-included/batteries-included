defmodule CommonCore.Batteries.SSOConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :sso
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :dev, :boolean, default: true
    type_field()
  end
end
