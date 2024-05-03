defmodule CommonCore.Batteries.KnativeConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :knative
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.knative()
    type_field()
  end
end
