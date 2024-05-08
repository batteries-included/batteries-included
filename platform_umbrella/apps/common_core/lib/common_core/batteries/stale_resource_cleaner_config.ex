defmodule CommonCore.Batteries.StaleResourceCleanerConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :stale_resource_cleaner do
    defaultable_field :delay, :integer, default: 900_000
  end
end
