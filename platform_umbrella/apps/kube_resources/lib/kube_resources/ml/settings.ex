defmodule KubeResources.MLSettings do
  @namespace "battery-core"
  @public_namespace "battery-ml"

  def namespace(config), do: Map.get(config, "namespace", @namespace)

  def public_namespace(config), do: Map.get(config, "namespace.public", @public_namespace)
end
