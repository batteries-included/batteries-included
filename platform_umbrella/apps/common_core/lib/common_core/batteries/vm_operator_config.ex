defmodule CommonCore.Batteries.VMOperatorConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :vm_operator
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :vm_operator_image, :string, default: Defaults.Images.vm_operator_image()
    type_field()
  end
end
