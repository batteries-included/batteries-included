defmodule KubeResources.DatabaseServiceMonitors do
  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster
  alias KubeRawResources.Database, as: RawDatabase

  def monitors(config) do
    services_and_montitors(Postgres.normal_clusters(), config)
  end

  def internal_monitors(config) do
    services_and_montitors(Postgres.internal_clusters(), config)
  end

  def services_and_montitors(clusters, config) do
    Enum.flat_map(clusters, fn cluster ->
      services(cluster, config) ++ postgres_monitors(cluster, config)
    end)
  end

  defp services(%Cluster{num_instances: num_instances} = cluster, config)
       when is_integer(num_instances) and num_instances > 1 do
    [
      RawDatabase.metrics_service(cluster, config, "master"),
      RawDatabase.metrics_service(cluster, config, "replica")
    ]
  end

  defp services(%Cluster{num_instances: _num_instances} = cluster, config) do
    [RawDatabase.metrics_service(cluster, config, "master")]
  end

  defp postgres_monitors(%Cluster{num_instances: num_instances} = cluster, config)
       when is_integer(num_instances) and num_instances > 1 do
    [
      RawDatabase.service_monitor(cluster, config, "master"),
      RawDatabase.service_monitor(cluster, config, "replica")
    ]
  end

  defp postgres_monitors(%Cluster{} = cluster, config) do
    [RawDatabase.service_monitor(cluster, config, "master")]
  end
end
