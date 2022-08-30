defmodule KubeRawResources.ServiceConfigs do
  def dev_services do
    Application.get_env(:kube_raw_resources, :dev_services, [])
  end

  def prod_services do
    Application.get_env(:kube_raw_resources, :prod_services, [])
  end
end
