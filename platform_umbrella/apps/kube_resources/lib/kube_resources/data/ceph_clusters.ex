defmodule KubeResources.CephClusters do
  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  def materialize(battery, state) do
    clusters(battery, state)
  end

  def clusters(battery, state) do
    state.ceph_clusters
    |> Enum.with_index()
    |> Enum.map(fn {ceph_cluster, idx} ->
      {cluster_path(ceph_cluster, idx), cluster(ceph_cluster, battery, state)}
    end)
    |> Enum.into(%{})
  end

  defp cluster_path(%{id: id} = _ceph_cluster, _idx), do: "/ceph_cluster/#{id}"
  defp cluster_path(_ceph_cluster, idx), do: "/ceph_cluster:idx/#{idx}"

  def cluster(%{} = cluster, battery, state) do
    namespace = data_namespace(state)

    B.build_resource(:ceph_cluster)
    |> B.name(cluster.name)
    |> B.namespace(namespace)
    |> B.owner_label(cluster.id)
    |> B.spec(cluster_spec(cluster, battery, state))
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
