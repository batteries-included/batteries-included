defmodule KubeResources.NetworkSettings do
  import KubeExt.MapSettings

  @ip_pools ["172.18.128.0/24"]

  setting(:metallb_ip_pools, :ip_pools, @ip_pools)
end
