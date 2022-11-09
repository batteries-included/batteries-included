defmodule KubeResources.CephFilesystems do
  alias KubeExt.Builder, as: B
  alias KubeResources.DataSettings, as: Settings

  def materialize(battery, state) do
    filesystems(battery, state)
  end

  def filesystems(battery, state) do
    state.ceph_filesystems
    |> Enum.with_index()
    |> Enum.map(fn {fs, idx} ->
      {filesystem_path(fs, idx), filesystem(fs, battery, state)}
    end)
    |> Enum.into(%{})
  end

  defp filesystem_path(%{id: id} = _fs, _idx), do: "/ceph_filesystem/#{id}"
  defp filesystem_path(_fs, idx), do: "/ceph_filesystem:idx/#{idx}"

  def filesystem(%{} = filesystem, battery, state) do
    namespace = Settings.public_namespace(battery.config)

    B.build_resource(:ceph_filesystem)
    |> B.name(filesystem.name)
    |> B.namespace(namespace)
    |> B.owner_label(filesystem.id)
    |> B.spec(filesystem_spec(filesystem, battery, state))
  end

  defp filesystem_spec(%{} = cluster, _battery, _state) do
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
