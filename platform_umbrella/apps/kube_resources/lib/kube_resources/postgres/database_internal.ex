defmodule KubeResources.DatabaseInternal do
  use KubeExt.ResourceGenerator
  import KubeExt.SystemState.Namespaces

  alias KubeResources.Database
  alias KubeResources.PostgresPod

  @master_role "master"
  @replica_role "replica"

  multi_resource(:postgres_internal_clusters, battery, state) do
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :internal end)
    |> Enum.map(fn cluster ->
      Database.postgres(cluster, battery, state)
    end)
  end

  multi_resource(:postgres_internal_master_metrics_service, battery, state) do
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :internal end)
    |> Enum.map(fn cluster ->
      Database.metrics_service(cluster, battery, state, @master_role)
    end)
  end

  multi_resource(:postgres_internal_master_service_monitor, battery, state) do
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :internal end)
    |> Enum.map(fn cluster ->
      Database.service_monitor(cluster, battery, state, @master_role)
    end)
  end

  multi_resource(:postgres_internal_replica_metrics_service, battery, state) do
    # On clusters that have replication add a service for metrics
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :internal && cluster.num_instances > 1 end)
    |> Enum.map(fn cluster ->
      Database.metrics_service(cluster, battery, state, @replica_role)
    end)
  end

  multi_resource(:postgres_internal_replica_service_monitor, battery, state) do
    # On clusters that have replication add their service monitor
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :internal && cluster.num_instances > 1 end)
    |> Enum.map(fn cluster ->
      Database.service_monitor(cluster, battery, state, @replica_role)
    end)
  end

  multi_resource(:postgres_pod_per_namespace, _battery, state) do
    namespace = base_namespace(state)
    PostgresPod.per_namespace(namespace)
  end
end
