defmodule KubeRawResources.NetworkSettings do
  import KubeExt.MapSettings

  @namespace "battery-core"
  @istio_namespace "battery-istio"

  setting(:namespace, :namespace, @namespace)
  setting(:istio_namespace, :namespace, @istio_namespace)
end
