defmodule CommonCore.ET.NamespaceReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  import CommonCore.ET.ReportTools

  alias CommonCore.Resources.FieldAccessors
  alias CommonCore.StateSummary

  batt_embedded_schema do
    field :pod_counts, :map
  end

  def new(%StateSummary{} = state_summary) do
    pod_counts = count_pods_by(state_summary, &FieldAccessors.namespace/1)

    CommonCore.Ecto.Schema.schema_new(__MODULE__, pod_counts: pod_counts)
  end

  def new(opts) do
    CommonCore.Ecto.Schema.schema_new(__MODULE__, opts)
  end
end
