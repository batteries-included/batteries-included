defmodule CommonCore.Batteries.VMOperatorConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :vm_operator
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :vm_operator_image, :string, default: Defaults.Images.vm_operator_image()
    type_field()
  end
end
