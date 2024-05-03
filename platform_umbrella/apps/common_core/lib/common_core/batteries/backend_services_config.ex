defmodule CommonCore.Batteries.BackendServicesConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :backend_services
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.backend()

    type_field()
  end
end
