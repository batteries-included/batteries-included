defmodule CommonCore.Resources.StorageClass do
  @moduledoc false
  alias CommonCore.Resources.Builder, as: B

  def generate_eks_storage_classes do
    [
      build_storage_class(nil, name: "gp2", provisioner: "kubernetes.io/aws-ebs", allow_volume_expansion: false),
      build_storage_class(%{"csi.storage.k8s.io/fstype" => "ext4", "type" => "gp2", "encrypted" => "true"}),
      build_storage_class(%{"csi.storage.k8s.io/fstype" => "ext4", "type" => "gp3", "encrypted" => "true"},
        default: "true"
      )
    ]
  end

  defp build_storage_class(params, opts \\ [])

  defp build_storage_class(nil = _params, opts) do
    :storage_class
    |> B.build_resource()
    |> B.name(Keyword.fetch!(opts, :name))
    |> B.annotation("storageclass.kubernetes.io/is-default-class", Keyword.get(opts, :default, "false"))
    |> Map.put("provisioner", Keyword.get(opts, :provisioner, "ebs.csi.aws.com"))
    |> Map.put("reclaimPolicy", Keyword.get(opts, :reclaim_policy, "Delete"))
    |> Map.put("volumeBindingMode", Keyword.get(opts, :volume_binding_mode, "WaitForFirstConsumer"))
    |> Map.put("allowVolumeExpansion", Keyword.get(opts, :allow_volume_expansion, true))
  end

  defp build_storage_class(%{} = params, opts) do
    nil
    |> build_storage_class(Keyword.put_new(opts, :name, "#{params["type"]}-#{:erlang.phash2(params)}"))
    |> Map.put("parameters", params)
  end
end
