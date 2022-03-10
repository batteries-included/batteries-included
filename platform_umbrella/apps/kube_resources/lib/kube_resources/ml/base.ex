defmodule KubeResources.ML.Base do
  alias KubeExt.Builder, as: B
  alias KubeResources.MLSettings

  @app "battery-ml"

  def materialize(config) do
    %{
      "/namespace" => namespace(config)
    }
  end

  defp namespace(config) do
    namespace = MLSettings.public_namespace(config)

    B.build_resource(:namespace)
    |> B.name(namespace)
    |> B.app_labels(@app)
  end
end
