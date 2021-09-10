defmodule KubeResources.BatteryIngress do
  alias KubeResources.ControlServer
  alias KubeResources.EchoServer

  def ingress(config) do
    [EchoServer.ingress(config), ControlServer.ingress(config)]
  end
end
