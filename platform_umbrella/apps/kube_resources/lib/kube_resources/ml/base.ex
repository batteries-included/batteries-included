defmodule KubeResources.ML.Base do
  alias KubeExt.Builder, as: B
  alias KubeResources.MLSettings

  @app "battery-ml"

  def materialize(battery, state) do
    %{
      "/namespace" => namespace(battery, state)
    }
  end

  defp namespace(battery, _state) do
    namespace = MLSettings.public_namespace(battery.config)

    B.build_resource(:namespace)
    |> B.name(namespace)
    |> B.app_labels(@app)
    |> B.label("istio-injection", "enabled")
  end
end
