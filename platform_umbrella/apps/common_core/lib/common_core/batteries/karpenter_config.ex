defmodule CommonCore.Batteries.KarpenterConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  @read_only_fields ~w(queue_name service_role_arn node_role_name)a

  batt_polymorphic_schema type: :karpenter do
    defaultable_image_field :image, image_id: :karpenter
    field :queue_name, :string
    field :service_role_arn, :string
    field :node_role_name, :string

    defaultable_field :ami_alias, :string, default: "al2@v20250123"
  end
end
