defmodule CommonCore.Batteries.GrafanaConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:admin_password]}

  alias CommonCore.Defaults

  @required_fields ~w()a

  batt_polymorphic_schema type: :grafana do
    defaultable_field :image, :string, default: Defaults.Images.grafana_image()
    defaultable_field :sidecar_image, :string, default: Defaults.Images.kiwigrid_sidecar_image()

    secret_field :admin_password
  end
end
