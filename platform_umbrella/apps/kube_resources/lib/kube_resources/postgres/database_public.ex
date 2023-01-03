defmodule KubeResources.DatabasePublic do
  use KubeExt.ResourceGenerator

  import CommonCore.SystemState.Namespaces

  alias KubeResources.Database
  alias KubeResources.PostgresPod

  @master_role "master"
  @replica_role "replica"

  multi_resource(:postgres_standard_clusters, battery, state) do
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :standard end)
    |> Enum.map(fn cluster ->
      Database.postgres(cluster, battery, state)
    end)
  end

  multi_resource(:postgres_standard_master_metrics_service, battery, state) do
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :standard end)
    |> Enum.map(fn cluster ->
      Database.metrics_service(cluster, battery, state, @master_role)
    end)
  end

  multi_resource(:postgres_standard_master_service_monitor, battery, state) do
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :standard end)
    |> Enum.map(fn cluster ->
      Database.service_monitor(cluster, battery, state, @master_role)
    end)
  end

  multi_resource(:postgres_standard_replica_metrics_service, battery, state) do
    # On clusters that have replication add a service for metrics
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :standard && cluster.num_instances > 1 end)
    |> Enum.map(fn cluster ->
      Database.metrics_service(cluster, battery, state, @replica_role)
    end)
  end

  multi_resource(:postgres_standard_replica_service_monitor, battery, state) do
    # On clusters that have replication add their service monitor
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :standard && cluster.num_instances > 1 end)
    |> Enum.map(fn cluster ->
      Database.service_monitor(cluster, battery, state, @replica_role)
    end)
  end

  multi_resource(:postgres_pod_per_namespace, _battery, state) do
    namespace = data_namespace(state)
    PostgresPod.per_namespace(namespace)
  end
end
