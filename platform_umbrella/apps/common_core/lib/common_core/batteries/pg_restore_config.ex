defmodule CommonCore.Batteries.PostgresRestoreConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :postgres_restore do
  end
end
