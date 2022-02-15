defmodule KubeResources.KubeMonitoring do
  alias KubeResources.KubeState
  alias KubeResources.NodeExporter

  def materialize(config) do
    %{
      "/node/service_account" => NodeExporter.service_account(config),
      "/node/cluster_role" => NodeExporter.cluster_role(config),
      "/node/bind" => NodeExporter.cluster_binding(config),
      "/kube/service_account" => KubeState.service_account(config),
      "/kube/cluster_role" => KubeState.cluster_role(config),
      "/kube/bind" => KubeState.cluster_binding(config),
      "/node/daemon" => NodeExporter.daemonset(config),
      "/node/service" => NodeExporter.service(config),
      "/kube/daemon" => KubeState.deployment(config),
      "/kube/service" => KubeState.service(config)
    }
  end

  def monitors(config) do
    NodeExporter.monitors(config) ++ KubeState.monitors(config)
  end
end
