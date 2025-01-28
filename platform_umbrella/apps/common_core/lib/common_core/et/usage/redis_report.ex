defmodule CommonCore.ET.RedisReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.Schema
  alias CommonCore.StateSummary

  batt_embedded_schema do
    field :instance_counts, :map
  end

  def new(%StateSummary{redis_instances: clusters} = _state_summary) do
    instance_counts =
      Map.new(clusters, fn cluster ->
        {cluster_key(cluster), cluster.num_instances}
      end)

    Schema.schema_new(__MODULE__,
      instance_counts: instance_counts
    )
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end

  defp cluster_key(cluster) do
    "#{cluster.type}.#{cluster.name}"
  end
end
