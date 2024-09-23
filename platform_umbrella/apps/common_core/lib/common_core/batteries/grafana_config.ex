defmodule CommonCore.Batteries.GrafanaConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:admin_password]}

  @required_fields ~w()a
  @read_only_fields ~w(admin_password)a

  batt_polymorphic_schema type: :grafana do
    defaultable_image_field :image, image_id: :grafana
    defaultable_image_field :sidecar_image, image_id: :kiwigrid_sidecar

    secret_field :admin_password
  end
end
