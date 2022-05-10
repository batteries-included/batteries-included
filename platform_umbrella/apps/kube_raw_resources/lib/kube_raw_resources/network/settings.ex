defmodule KubeRawResources.NetworkSettings do
  @namespace "battery-core"
  @istio_namespace "battery-istio"
  @istio_ingress_namespace "battery-ingress"

  def namespace(config), do: Map.get(config, "namespace", @namespace)
  def istio_namespace(config), do: Map.get(config, "istio.namespace", @istio_namespace)

  def ingress_namespace(config),
    do: Map.get(config, "istio.ingress.namespace", @istio_ingress_namespace)
end
