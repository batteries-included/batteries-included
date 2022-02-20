defmodule KubeResources.ControlServerResources do
  alias KubeExt.Builder, as: B
  alias KubeRawResources.BatterySettings
  alias KubeRawResources.ControlServerResources, as: RawControlServerResources
  alias KubeResources.IstioConfig.VirtualService

  @app_name "control-server"

  defdelegate materialize(config), to: RawControlServerResources

  def virtual_service(config) do
    namespace = BatterySettings.namespace(config)

    B.build_resource(:virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("control-server")
    |> B.spec(VirtualService.fallback("control-server"))
  end

  def ingress(config) do
    namespace = BatterySettings.namespace(config)

    B.build_resource(:ingress, "/", "control-server", "http")
    |> B.name("control-server")
    |> B.annotation("nginx.org/websocket-services", "control-server")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end
end
