defmodule CommonCore.Batteries.CloudnativePGConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :cloudnative_pg do
    defaultable_field :image, :string, default: Defaults.Images.cloudnative_pg_image()
  end
end
