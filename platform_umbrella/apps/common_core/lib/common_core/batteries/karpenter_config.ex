defmodule CommonCore.Batteries.KarpenterConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :karpenter
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.karpenter_image()
    field :queue_name, :string
    field :service_role_arn, :string
    field :node_role_name, :string
    type_field()
  end
end
