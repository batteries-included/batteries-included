defmodule CommonCore.Batteries.CloudnativePGBarmanConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :cloudnative_pg_barman do
    defaultable_image_field :barman_plugin_image, image_id: :cnpg_plugin_barman
    defaultable_image_field :barman_plugin_sidecar_image, image_id: :cnpg_plugin_barman_sidecar

    # These are duplicated / migrated from cloudnativepgconfig
    field :service_role_arn, :string
    field :bucket_name, :string
    field :bucket_arn, :string
  end
end
