defmodule CommonCore.ET.PostgresReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.Schema
  alias CommonCore.StateSummary

  batt_embedded_schema do
    # Count of postgres cluster to number of instances configured
    field :instance_counts, :map
  end

  def new(%StateSummary{postgres_clusters: clusters} = _state_summary) do
    instance_counts =
      Map.new(clusters, fn cluster ->
        {"#{cluster.type}.#{cluster.name}", cluster.num_instances}
      end)

    Schema.schema_new(__MODULE__, instance_counts: instance_counts)
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end
end
