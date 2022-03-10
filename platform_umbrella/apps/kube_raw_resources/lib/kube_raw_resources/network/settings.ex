defmodule KubeRawResources.NetworkSettings do
  @namespace "battery-core"

  def namespace(config), do: Map.get(config, "namespace", @namespace)
end
