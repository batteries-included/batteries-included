defmodule CommonCore.Batteries.AzureKarpenterConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  @read_only_fields ~w(subscription_id resource_group_name tenant_id)a

  # Default Azure instance types for Karpenter node provisioning
  # These instance types were selected for:
  # - Standard_D2s_v3: Entry-level general purpose workloads (2 vCPUs, 8 GiB RAM)
  # - Standard_D4s_v3: Medium workloads with balanced compute/memory (4 vCPUs, 16 GiB RAM)
  # - Standard_D8s_v3: Larger workloads requiring more resources (8 vCPUs, 32 GiB RAM)
  # All are from the Dsv3 series which offers:
  # - Premium SSD support for better I/O performance
  # - Cost-effective general purpose compute
  # - Good balance of CPU, memory, and temporary storage
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
  end
end
