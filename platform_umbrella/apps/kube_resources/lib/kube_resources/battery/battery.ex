defmodule KubeResources.Battery do
  alias KubeExt.Builder, as: B

  @app_name "batteries-included"

  def namespace(battery, _state) do
    B.build_resource(:namespace)
    |> B.app_labels(@app_name)
    |> B.name(battery.config.namespace)
    |> B.label("istio-injection", "enabled")
  end

  def materialize(battery, state) do
    %{
      "/namespace" => namespace(battery, state)
    }
  end
end
