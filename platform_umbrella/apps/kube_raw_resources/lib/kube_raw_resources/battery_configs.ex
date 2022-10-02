defmodule KubeRawResources.BatteryConfigs do
  def dev_batteries do
    Application.get_env(:kube_raw_resources, :dev_batteries, [])
  end

  def prod_batteries do
    # At some point this will need to be
    # removed for a cluster/setting specific method.
    Application.get_env(:kube_raw_resources, :prod_batteries, [])
  end
end
