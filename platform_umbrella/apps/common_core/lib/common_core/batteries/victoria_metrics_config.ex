defmodule CommonCore.Batteries.VictoriaMetricsConfig do
  @moduledoc false

  use CommonCore, :embedded_schema
  use CommonCore.Util.PolymorphicType, type: :victoria_metrics

  typed_embedded_schema do
    type_field()
  end
end
