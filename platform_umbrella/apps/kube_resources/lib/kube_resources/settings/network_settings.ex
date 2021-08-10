defmodule KubeResources.NetworkSettings do
  @namespace "battery-network"

  def namespace(config), do: Map.get(config, "namespace", @namespace)
end
