defmodule KubeExt.Defaults.Network do
  def metallb_ip_pools, do: ["172.18.128.0/24"]
end
