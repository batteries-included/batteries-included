defmodule CommonCore.Batteries.AwsLoadBalancerControllerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :aws_load_balancer_controller
  use CommonCore.Util.DefaultableField

  alias CommonCore.Defaults

  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.aws_load_balancer_controller_image()
    field :service_role_arn, :string

    type_field()
  end
end
