defmodule KubeResources.CephClusters do
  alias ControlServer.Rook
  alias KubeExt.Builder, as: B
  alias KubeRawResources.DataSettings, as: Settings

  def materialize(%{} = config) do
    clusters(config)
  end

  def clusters(config) do
    Rook.list_ceph_cluster()
    |> Enum.map(fn ceph_cluster ->
      {"/ceph_cluster/#{ceph_cluster.id}", cluster(ceph_cluster, config)}
    end)
    |> Enum.into(%{})
  end

  def cluster(%Rook.CephCluster{} = cluster, config) do
    namespace = Settings.public_namespace(config)

    B.build_resource(:ceph_cluster)
    |> B.name(cluster.name)
    |> B.namespace(namespace)
    |> B.owner_label(cluster.id)
    |> B.spec(cluster_spec(cluster, config))
  end

  defp cluster_spec(%Rook.CephCluster{} = cluster, config) do
    ceph_image = Settings.ceph_image(config)

    %{
      # storage: %{useAllNodes: false, useAllDevices: false, nodes: cluster.nodes},
      network: %{connections: %{encryption: %{enabled: false}, compression: %{enabled: false}}},
      dataDirHostPath: cluster.data_dir_host_path,
      mon: %{count: cluster.num_mon},
      mgr: %{count: cluster.num_mgr},
      cephVersion: %{image: ceph_image}
    }
  end
end
