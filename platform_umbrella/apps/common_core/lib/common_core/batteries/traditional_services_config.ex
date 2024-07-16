defmodule CommonCore.Batteries.TraditionalServicesConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :traditional_services do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.backend()
  end
end
