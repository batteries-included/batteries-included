defmodule CommonCore.Batteries.BackendServicesConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :backend_services
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.backend()

    type_field()
  end
end
