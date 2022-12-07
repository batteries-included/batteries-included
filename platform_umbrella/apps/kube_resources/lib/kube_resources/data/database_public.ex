defmodule KubeResources.DatabasePublic do
  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeResources.Database
  alias KubeResources.PostgresPod

  multi_resource(:postgres_standard_clusters, battery, state) do
    state.postgres_clusters
    |> Enum.filter(fn cluster -> cluster.type == :standard end)
    |> Enum.map(fn cluster ->
      Database.postgres(cluster, battery, state)
    end)
  end

  multi_resource(:postgres_pod_per_namespace, _battery, state) do
    namespace = data_namespace(state)
    PostgresPod.per_namespace(namespace)
  end
end
