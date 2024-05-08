defmodule CommonCore.ET.RedisReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  alias CommonCore.StateSummary

  batt_embedded_schema do
    field :instance_counts, :map
    field :sentinel_instance_counts, :map
  end

  def new(%StateSummary{redis_clusters: clusters} = _state_summary) do
    instance_counts =
      Map.new(clusters, fn cluster ->
        {cluster_key(cluster), cluster.num_redis_instances}
      end)

    sentinel_instance_counts =
      Map.new(clusters, fn cluster ->
        {cluster_key(cluster), cluster.num_sentinel_instances}
      end)

    CommonCore.Ecto.Schema.schema_new(__MODULE__,
      instance_counts: instance_counts,
      sentinel_instance_counts: sentinel_instance_counts
    )
  end

  def new(opts) do
    CommonCore.Ecto.Schema.schema_new(__MODULE__, opts)
  end

  defp cluster_key(cluster) do
    "#{cluster.type}.#{cluster.name}"
  end
end
