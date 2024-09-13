defmodule CommonCore.ET.NamespaceReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  import CommonCore.ET.ReportTools

  alias CommonCore.Ecto.Schema
  alias CommonCore.Resources.FieldAccessors
  alias CommonCore.StateSummary

  batt_embedded_schema do
    field :pod_counts, :map
  end

  def new(%StateSummary{} = state_summary) do
    pod_counts = count_pods_by(state_summary, &FieldAccessors.namespace/1)

    Schema.schema_new(__MODULE__, pod_counts: pod_counts)
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end

  def total_battery_pods(%__MODULE__{pod_counts: pod_counts}) do
    Enum.reduce(pod_counts, 0, fn {namespace, count}, acc ->
      if String.starts_with?(namespace, "battery-"), do: acc + count, else: acc
    end)
  end

  def total_battery_pods(_), do: 0
end
