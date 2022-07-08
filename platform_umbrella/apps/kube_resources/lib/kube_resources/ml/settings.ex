defmodule KubeResources.MLSettings do
  import KubeExt.MapSettings

  @namespace "battery-core"
  @public_namespace "battery-ml"

  setting(:namespace, :namespace, @namespace)
  setting(:public_namespace, :namespace, @public_namespace)
end
