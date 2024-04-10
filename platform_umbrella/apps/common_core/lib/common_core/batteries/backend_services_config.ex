defmodule CommonCore.Batteries.BackendServicesConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :backend_services
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    type_field()
  end
end
