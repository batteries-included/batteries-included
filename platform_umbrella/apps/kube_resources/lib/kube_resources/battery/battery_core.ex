defmodule KubeResources.BatteryCore do
  use KubeExt.ResourceGenerator

  alias KubeExt.Builder, as: B

  @app_name "batteries-included"

  resource(:core_namespace, battery, _state) do
    B.build_resource(:namespace)
    |> B.app_labels(@app_name)
    |> B.name(battery.config.core_namespace)
    |> B.label("istio-injection", "enabled")
  end

  resource(:base_namespace, battery, _state) do
    B.build_resource(:namespace)
    |> B.app_labels(@app_name)
    |> B.name(battery.config.base_namespace)
    |> B.label("istio-injection", "false")
  end
end
