defmodule KubeRawResources.NetworkSettings do
  @namespace "battery-core"
  @istio_namespace "battery-ingress"

  def namespace(config), do: Map.get(config, "namespace", @namespace)
  def ingress_namespace(config), do: Map.get(config, "istio.namespace", @istio_namespace)
end
