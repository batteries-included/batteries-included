defmodule ControlServer.Settings.BatterySettings do
  @namespace "battery-core"

  @control_image "k3d-k3s-default-registry:5000/battery/control"
  @control_version "bd46c0a-dirty"
  @control_name "control-server"

  def namespace(config), do: Map.get(config, "namespace", @namespace)
  def control_server_image(config), do: Map.get(config, "control:image", @control_image)
  def control_server_version(config), do: Map.get(config, "control:version", @control_version)
  def control_server_name(config), do: Map.get(config, "control:name", @control_name)
end
