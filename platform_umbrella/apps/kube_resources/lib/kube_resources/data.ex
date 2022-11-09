defmodule KubeResources.Data do
  alias KubeExt.Builder, as: B
  alias KubeResources.DataSettings

  @app "data-common"

  def materialize(battery, state) do
    %{
      "/namespace" => namespace(battery, state)
    }
  end

  defp namespace(battery, _state) do
    namespace = DataSettings.public_namespace(battery.config)

    B.build_resource(:namespace)
    |> B.name(namespace)
    |> B.app_labels(@app)
  end
end
