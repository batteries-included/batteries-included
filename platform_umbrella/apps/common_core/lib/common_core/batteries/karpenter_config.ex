defmodule CommonCore.Batteries.KarpenterConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :karpenter
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.karpenter_image()
    field :cluster_name, :string
    field :queue_name, :string
    field :service_role_arn, :string
    field :node_role_name, :string
    type_field()
  end
end
