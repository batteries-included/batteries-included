defmodule KubeResources.BatteryIngress do
  alias KubeResources.EchoServer

  def ingress(config) do
    EchoServer.ingress(config)
  end
end
