defmodule CommonCore.Resources.BatteryCore do
  @moduledoc false
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

  resource(:base_namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.base_namespace)
    |> B.label("elbv2.k8s.aws/service-webhook", "disabled")
  end

  resource(:data_namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.data_namespace)
    |> B.label("istio-injection", "enabled")
  end

  resource(:ml_namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.ml_namespace)
    |> B.label("istio-injection", "enabled")
  end

  multi_resource(:storage_class, battery) do
    Enum.filter(generate_eks_storage_classes(), fn sc ->
      F.require(sc, battery.config.cluster_type == :aws)
    end)
  end
end
