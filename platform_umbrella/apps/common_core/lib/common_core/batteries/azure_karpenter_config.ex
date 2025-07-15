defmodule CommonCore.Batteries.AzureKarpenterConfig do
  @moduledoc false

  use CommonCore.Batteries.Battery,
    battery_type: :azure_karpenter,
    resource_module: CommonCore.Resources.AzureKarpenter

  alias CommonCore.Resources.FilterResource, as: F

  defstruct [
    :subscription_id,
    :resource_group_name,
    :location,
    :tenant_id,
    :client_id,
    :image
  ]

  def new(params \\ %{}) do
    %__MODULE__{
      subscription_id: params[:subscription_id],
      resource_group_name: params[:resource_group_name],
      location: params[:location],
      tenant_id: params[:tenant_id],
      client_id: params[:client_id],
      image: params[:image] || "mcr.microsoft.com/oss/azure/karpenter/karpenter:v0.37.0"
    }
  end

  def battery_config_to_filter_resource(battery_config) do
    battery_config
    |> F.require_non_nil(:subscription_id)
    |> F.require_non_nil(:resource_group_name)
    |> F.require_non_nil(:location)
    |> F.require_non_nil(:tenant_id)
    |> F.require_non_nil(:client_id)
    |> F.require_non_nil(:image)
  end
end