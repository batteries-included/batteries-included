defmodule CommonCore.Batteries.KnativeConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :knative do
    defaultable_field :namespace, :string, default: Defaults.Namespaces.knative()
  end
end
