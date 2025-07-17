defmodule CommonCore.Batteries.AzureKarpenterConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  @read_only_fields ~w(subscription_id resource_group_name tenant_id)a

  batt_polymorphic_schema type: :azure_karpenter do
    defaultable_image_field :image, image_id: :azure_karpenter
    field :subscription_id, :string
    field :resource_group_name, :string
    field :location, :string
    field :tenant_id, :string
    field :client_id, :string
    field :cluster_name, :string
    field :node_resource_group, :string
  end
end
