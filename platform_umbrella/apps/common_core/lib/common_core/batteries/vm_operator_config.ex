defmodule CommonCore.Batteries.VMOperatorConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :vm_operator do
    defaultable_field :vm_operator_image, :string, default: Defaults.Images.vm_operator_image()
  end
end
