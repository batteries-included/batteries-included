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
    defaultable_field :scale_down_delay_after_add, :integer, default: 600  # seconds (10 minutes)
    defaultable_field :scale_down_unneeded_time, :integer, default: 600    # seconds (10 minutes)
    defaultable_field :max_node_provision_time, :integer, default: 900     # seconds (15 minutes)
    defaultable_field :cpu_limit, :string, default: "100m"
    defaultable_field :memory_limit, :string, default: "300Mi"
    defaultable_field :cpu_request, :string, default: "100m"
    defaultable_field :memory_request, :string, default: "300Mi"
  end
end
