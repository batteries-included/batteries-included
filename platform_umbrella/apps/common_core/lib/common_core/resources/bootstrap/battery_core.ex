defmodule CommonCore.Resources.Bootstrap.BatteryCore do
  @moduledoc false

  # Use the same app_name so that core_namespace
  # is labeled  with the same app_name as the other namespaces
  use CommonCore.Resources.ResourceGenerator, app_name: "battery-core"

  import CommonCore.Resources.StorageClass

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:core_namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.core_namespace)
    |> B.label("istio-injection", "enabled")
  end

  multi_resource(:storage_class, battery) do
    Enum.filter(generate_eks_storage_classes(), fn sc ->
      F.require(sc, battery.config.cluster_type == :aws)
    end)
  end
end
