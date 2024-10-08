defmodule CommonCore.ET.NamespaceReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  import CommonCore.ET.ReportTools

  alias CommonCore.Ecto.Schema
  alias CommonCore.Resources.FieldAccessors
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Namespaces

  batt_embedded_schema do
    field :pod_counts, :map
  end

  def new(%StateSummary{} = state_summary) do
    pod_counts = count_pods_by(state_summary, &FieldAccessors.namespace/1)
    battery_namespaces = Namespaces.all_namespaces(state_summary)

    Schema.schema_new(__MODULE__, pod_counts: Map.take(pod_counts, battery_namespaces))
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end

  def pod_count(%__MODULE__{pod_counts: pod_counts}) do
    pod_counts |> Map.values() |> Enum.sum()
  end

  def pod_count(_), do: 0
end
