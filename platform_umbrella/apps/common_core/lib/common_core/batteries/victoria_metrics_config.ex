defmodule CommonCore.Batteries.VictoriaMetricsConfig do
  @moduledoc false
  use CommonCore.Util.PolymorphicType, type: :victoria_metrics
  use TypedEctoSchema

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    type_field()
  end
end
