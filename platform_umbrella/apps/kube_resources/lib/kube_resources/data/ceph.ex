defmodule KubeResources.Ceph do
  alias ControlServer.Rook
  alias KubeExt.Builder, as: B
  alias KubeRawResources.DataSettings, as: Settings

  def materialize(%{} = config) do
    %{}
    |> Map.merge(clusters(config))
    |> Map.merge(filesystems(config))
  end

  def clusters(config) do
    Rook.list_ceph_cluster()
    |> Enum.map(fn ceph_cluster ->
      {"/ceph_cluster/#{ceph_cluster.id}", cluster(ceph_cluster, config)}
    end)
    |> Enum.into(%{})
  end

  def filesystems(config) do
    Rook.list_ceph_filesystem()
    |> Enum.map(fn fs ->
      {"/ceph_filesystem/#{fs.id}", filesystem(fs, config)}
    end)
    |> Enum.into(%{})
  end

  def cluster(%Rook.CephCluster{} = cluster, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:ceph_cluster)
    |> B.name(cluster.name)
    |> B.namespace(namespace)
    |> B.owner_label(cluster.id)
    |> B.spec(cluster_spec(cluster, config))
  end

  def filesystem(%Rook.CephFilesystem{} = filesystem, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:ceph_filesystem)
    |> B.name(filesystem.name)
    |> B.namespace(namespace)
    |> B.owner_label(filesystem.id)
    |> B.spec(filesystem_spec(filesystem, config))
  end

  defp filesystem_spec(%Rook.CephFilesystem{} = cluster, _config) do
    %{
      metadataPool: %{replicated: %{size: 3}},
      dataPools: filesystem_datapools(cluster.include_erasure_encoded)
    }
  end

  defp filesystem_datapools(true) do
    filesystem_datapools(false) ++
      [%{name: "erasurecoded", erasureCoded: %{dataChunks: 2, codingChunks: 1}}]
  end

  defp filesystem_datapools(_) do
    [%{name: "replicated", size: 3}]
  end

  defp cluster_spec(%Rook.CephCluster{} = cluster, config) do
    ceph_image = Settings.ceph_image(config)

    %{
      storage: %{useAllNodes: false, useAllDevices: false, nodes: cluster.nodes},
      network: %{connections: %{encryption: %{enabled: false}, compression: %{enabled: false}}},
      mon: %{count: cluster.num_mon},
      mgr: %{count: cluster.num_mgr},
      cephVersion: %{image: ceph_image}
    }
  end
end
