defmodule CommonCore.Batteries.TrivyOperatorConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :trivy_operator
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.trivy_operator_image()
    defaultable_field :version_tag, :string, default: "0.42.0"
    type_field()
  end
end
