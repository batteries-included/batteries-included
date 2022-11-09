defmodule KubeResources.NetworkSettings do
  import KubeExt.MapSettings

  @namespace "battery-core"
  @istio_namespace "battery-istio"
  @metallb_namespace "battery-loadbalancer"
  @ip_pools ["172.18.128.0/24"]

  setting(:namespace, :namespace, @namespace)
  setting(:istio_namespace, :namespace, @istio_namespace)

  setting(:metallb_namespace, :namespace, @metallb_namespace)
  setting(:metallb_ip_pools, :ip_pools, @ip_pools)
end
