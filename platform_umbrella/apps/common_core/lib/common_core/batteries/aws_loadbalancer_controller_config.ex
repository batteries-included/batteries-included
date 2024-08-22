defmodule CommonCore.Batteries.AwsLoadBalancerControllerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults.Images

  @battery_type :aws_load_balancer_controller

  batt_polymorphic_schema type: @battery_type do
    defaultable_field :image, :string, default: Images.get_image(@battery_type)
    field :image_version, :string, default: Images.get_version(@battery_type)
    field :service_role_arn, :string
    field :subnets, {:array, :string}
    field :eip_allocations, {:array, :string}
  end
end
