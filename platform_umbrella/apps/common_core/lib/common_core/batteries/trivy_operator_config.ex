defmodule CommonCore.Batteries.TrivyOperatorConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :trivy_operator
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.trivy_operator_image()
    defaultable_field :version_tag, :string, default: "0.42.0"
    type_field()
  end
end
