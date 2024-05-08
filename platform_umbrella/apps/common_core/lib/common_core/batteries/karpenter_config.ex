defmodule CommonCore.Batteries.KarpenterConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :karpenter do
    defaultable_field :image, :string, default: Defaults.Images.karpenter_image()
    field :queue_name, :string
    field :service_role_arn, :string
    field :node_role_name, :string
  end
end
