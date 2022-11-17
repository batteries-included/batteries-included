defmodule KubeExt.Defaults.Monitoring do
  def kubelet_service, do: "kube-system/battery-kubelet"

  def prometheus_version, do: "v2.39.2"
  def prometheus_retention, do: "10d"

  def alertmanager_version, do: "v0.24.0"

  def kiali_version, do: "v1.59.1"
end
