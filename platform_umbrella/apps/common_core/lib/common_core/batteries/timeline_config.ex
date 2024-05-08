defmodule CommonCore.Batteries.TimelineConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :timeline do
  end
end
