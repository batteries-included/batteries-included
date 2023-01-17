defmodule KubeResources.BatteryCore do
  use KubeExt.ResourceGenerator, app_name: "battery-core"

  alias KubeExt.Builder, as: B

  resource(:core_namespace, battery, _state) do
    B.build_resource(:namespace)
    |> B.name(battery.config.core_namespace)
    |> B.label("istio-injection", "enabled")
  end

  resource(:base_namespace, battery, _state) do
    B.build_resource(:namespace)
    |> B.name(battery.config.base_namespace)
    |> B.label("istio-injection", "false")
  end

  resource(:data_namespace, battery, _state) do
    B.build_resource(:namespace)
    |> B.name(battery.config.data_namespace)
    |> B.label("istio-injection", "false")
  end

  resource(:ml_namespace, battery, _state) do
    B.build_resource(:namespace)
    |> B.name(battery.config.ml_namespace)
    |> B.label("istio-injection", "enabled")
  end
end
