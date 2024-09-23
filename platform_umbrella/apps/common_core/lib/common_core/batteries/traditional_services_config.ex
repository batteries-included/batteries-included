defmodule CommonCore.Batteries.TraditionalServicesConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  @read_only_fields ~w(namespace)a

  batt_polymorphic_schema type: :traditional_services do
    field :namespace, :string, default: Defaults.Namespaces.traditional()
  end
end
