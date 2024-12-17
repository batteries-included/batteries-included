defmodule CommonCore.Batteries.CloudnativePGConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :cloudnative_pg do
    defaultable_image_field :image, image_id: :cloudnative_pg

    field :service_role_arn, :string
    field :bucket_name, :string
    field :bucket_arn, :string
  end
end
