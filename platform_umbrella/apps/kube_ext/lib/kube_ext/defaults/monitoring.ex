defmodule KubeExt.Defaults.Monitoring do
  def kubelet_service, do: "kube-system/battery-kubelet"
  def kiali_version, do: "v1.59.1"
end
