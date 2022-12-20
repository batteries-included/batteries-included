defmodule KubeResources.CephClusters do
  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  multi_resource(:clusters, battery, state) do
    namespace = data_namespace(state)

    Enum.map(state.ceph_clusters, fn cluster ->
      B.build_resource(:ceph_cluster)
      |> B.name(cluster.name)
      |> B.namespace(namespace)
      |> B.owner_label(cluster.id)
      |> B.spec(cluster_spec(cluster, battery, state))
    end)
  end

  defp cluster_spec(%{} = cluster, battery, _state) do
    %{
      # storage: %{useAllNodes: false, useAllDevices: false, nodes: cluster.nodes},
      network: %{connections: %{encryption: %{enabled: false}, compression: %{enabled: false}}},
      dataDirHostPath: cluster.data_dir_host_path,
      mon: %{count: cluster.num_mon},
      mgr: %{count: cluster.num_mgr},
      cephVersion: %{image: battery.image}
    }
  end
end
