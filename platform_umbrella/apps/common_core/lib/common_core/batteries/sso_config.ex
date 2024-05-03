defmodule CommonCore.Batteries.SSOConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :sso
  use CommonCore.Util.DefaultableField

  typed_embedded_schema do
    defaultable_field :dev, :boolean, default: true
    type_field()
  end
end
