defmodule KubeResources.ML.Core do
  alias KubeExt.Builder, as: B

  @app_name "battery-ml"

  def materialize(battery, state) do
    %{
      "/namespace" => namespace(battery, state)
    }
  end

  defp namespace(battery, _state) do
    B.build_resource(:namespace)
    |> B.name(battery.config.namespace)
    |> B.app_labels(@app_name)
    |> B.label("istio-injection", "enabled")
  end
end
