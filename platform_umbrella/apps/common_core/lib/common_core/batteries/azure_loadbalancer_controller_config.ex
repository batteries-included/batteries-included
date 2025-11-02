defmodule CommonCore.Batteries.AzureLoadBalancerControllerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  @read_only_fields ~w(resource_group_name subscription_id tenant_id)a

  batt_polymorphic_schema type: :azure_load_balancer_controller do
    defaultable_image_field :image, image_id: :azure_load_balancer_controller
    field :resource_group_name, :string
    field :subscription_id, :string
    field :tenant_id, :string
    field :cluster_name, :string
    field :location, :string
    field :node_resource_group, :string
    field :vnet_name, :string
    field :subnet_name, :string
    field :kubelet_identity_id, :string
  end
end
