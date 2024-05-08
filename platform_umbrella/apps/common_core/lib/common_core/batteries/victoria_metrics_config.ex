defmodule CommonCore.Batteries.VictoriaMetricsConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :victoria_metrics do
  end
end
