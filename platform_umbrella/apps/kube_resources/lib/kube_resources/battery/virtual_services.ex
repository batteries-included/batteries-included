defmodule KubeResources.Battery.VirtualServices do
  alias KubeResources.ControlServer
  alias KubeResources.EchoServer

  def vitrual_services(config) do
    [EchoServer.virtual_service(config), ControlServer.virtual_service(config)]
  end
end
