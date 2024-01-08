defmodule CommonCore.Batteries.KnativeConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :knative
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.knative()
    type_field()
  end
end
