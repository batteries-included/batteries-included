defmodule CommonCore.Batteries.AzureKarpenterConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  @read_only_fields ~w(subscription_id resource_group_name tenant_id)a

  # Default instance types for Azure node pools
  # D2s_v3: 2 vCPUs, 8 GB RAM - small workloads
  # D4s_v3: 4 vCPUs, 16 GB RAM - medium workloads
  # D8s_v3: 8 vCPUs, 32 GB RAM - larger workloads
  # Dsv3 series = SSD storage + good price/performance
  @default_instance_types ["Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3"]

  batt_polymorphic_schema type: :azure_karpenter do
    defaultable_image_field :image, image_id: :azure_karpenter
    field :subscription_id, :string
    field :resource_group_name, :string
    field :location, :string
    field :tenant_id, :string
    field :client_id, :string
    field :cluster_name, :string
    field :node_resource_group, :string
    defaultable_field :instance_types, {:array, :string}, default: @default_instance_types
    defaultable_field :image_family, :string, default: "Ubuntu2204"
    defaultable_field :image_version, :string, default: "202410.01.0"
  end
end
