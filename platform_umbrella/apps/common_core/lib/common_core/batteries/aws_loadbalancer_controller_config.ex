defmodule CommonCore.Batteries.AwsLoadBalancerControllerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :aws_load_balancer_controller do
    defaultable_image_field :image, image_id: :aws_load_balancer_controller
    field :service_role_arn, :string
    field :subnets, {:array, :string}
    field :eip_allocations, {:array, :string}
  end
end
