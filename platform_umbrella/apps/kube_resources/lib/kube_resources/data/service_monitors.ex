defmodule KubeResources.DatabaseServiceMonitors do
  alias KubeResources.Database

  def monitors(battery, state) do
    services_and_montitors(battery, state)
  end

  def services_and_montitors(battery, state) do
    Enum.flat_map(
      state.postgres_clusters,
      fn cluster ->
        services(cluster, battery, state) ++ postgres_monitors(cluster, battery, state)
      end
    )
  end

  defp services(%{num_instances: num_instances} = cluster, battery, state)
       when is_integer(num_instances) and num_instances > 1 do
    [
      Database.metrics_service(cluster, battery, state, "master"),
      Database.metrics_service(cluster, battery, state, "replica")
    ]
  end

  defp services(%{num_instances: _num_instances} = cluster, battery, state) do
    [Database.metrics_service(cluster, battery, state, "master")]
  end

  defp postgres_monitors(%{num_instances: num_instances} = cluster, battery, state)
       when is_integer(num_instances) and num_instances > 1 do
    [
      Database.service_monitor(cluster, battery, state, "master"),
      Database.service_monitor(cluster, battery, state, "replica")
    ]
  end

  defp postgres_monitors(%{} = cluster, battery, state) do
    [Database.service_monitor(cluster, battery, state, "master")]
  end
end
