defmodule KubeResources.BatterySettings do
  @namespace "battery-core"

  @control_image "k3d-k3s-default-registry:5000/battery/control"
  @control_version "afe4fa5-dirty"
  @control_name "control-server"

  @spec namespace(map) :: String.t()
  def namespace(config), do: Map.get(config, "namespace", @namespace)

  @spec control_server_image(map) :: String.t()
  def control_server_image(config), do: Map.get(config, "control:image", @control_image)

  @spec control_server_version(map) :: String.t()
  def control_server_version(config), do: Map.get(config, "control:version", @control_version)
  def control_server_name(config), do: Map.get(config, "control:name", @control_name)
end
