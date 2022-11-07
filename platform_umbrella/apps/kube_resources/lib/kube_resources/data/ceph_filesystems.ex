defmodule KubeResources.CephFilesystems do
  alias ControlServer.Rook
  alias KubeExt.Builder, as: B
  alias KubeRawResources.DataSettings, as: Settings

  def materialize(%{} = config) do
    filesystems(config)
  end

  def filesystems(config) do
    Rook.list_ceph_filesystem()
    |> Enum.map(fn fs ->
      {"/ceph_filesystem/#{fs.id}", filesystem(fs, config)}
    end)
    |> Enum.into(%{})
  end

  def filesystem(%Rook.CephFilesystem{} = filesystem, config) do
    namespace = Settings.public_namespace(config)

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
end
