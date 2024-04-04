defmodule CommonCore.Batteries.AwsLoadBalancerControllerConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :aws_load_balancer_controller
  use CommonCore.Util.DefaultableField
  use TypedEctoSchema

  alias CommonCore.Defaults

  @required_fields ~w()a

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    defaultable_field :image, :string, default: Defaults.Images.aws_load_balancer_controller_image()
    field :service_role_arn, :string

    type_field()
  end
end
