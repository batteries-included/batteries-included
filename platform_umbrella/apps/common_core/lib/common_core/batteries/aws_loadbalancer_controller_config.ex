defmodule CommonCore.Batteries.AwsLoadBalancerControllerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :aws_load_balancer_controller do
    defaultable_field :image, :string, default: Defaults.Images.aws_load_balancer_controller_image()
    field :service_role_arn, :string
  end
end
