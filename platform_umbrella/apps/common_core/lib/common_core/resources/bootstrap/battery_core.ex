defmodule CommonCore.Resources.Bootstrap.BatteryCore do
  @moduledoc false

  # Use the same app_name so that core_namespace
  # is labeled  with the same app_name as the other namespaces
  use CommonCore.Resources.ResourceGenerator, app_name: "battery-core"

  import CommonCore.Resources.StorageClass

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:bootstrap_config_map, battery, state) do
    :config_map
    |> B.build_resource()
    |> B.name("bootstrap-config")
    |> B.namespace(battery.config.core_namespace)
    |> B.data(%{
      "bootstrap.json" => Jason.encode!(state)
    })
  end

  resource(:core_namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.core_namespace)
    |> B.label("istio-injection", "enabled")
  end

  multi_resource(:storage_class, battery) do
    Enum.filter(generate_eks_storage_classes(), fn sc -> F.require(sc, battery.config.cluster_type == :eks) end)
  end

  # TODO(elliott): There should be a job here that call kube bootstrap and then
  # db bootstrap
end
