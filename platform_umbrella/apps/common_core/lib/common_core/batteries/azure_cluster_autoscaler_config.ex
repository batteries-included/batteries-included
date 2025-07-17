defmodule CommonCore.Batteries.AzureClusterAutoscalerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  @read_only_fields ~w(resource_group_name subscription_id tenant_id node_resource_group)a

  batt_polymorphic_schema type: :azure_cluster_autoscaler do
    defaultable_image_field :image, image_id: :azure_cluster_autoscaler
    field :resource_group_name, :string
    field :subscription_id, :string
    field :tenant_id, :string
    field :node_resource_group, :string
    field :cluster_name, :string
    defaultable_field :scale_down_delay_after_add, :string, default: "10m"
    defaultable_field :scale_down_unneeded_time, :string, default: "10m"
    defaultable_field :max_node_provision_time, :string, default: "15m"
  end
end
