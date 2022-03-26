defmodule KubeResources.Data do
  alias KubeExt.Builder, as: B
  alias KubeRawResources.DataSettings

  @app "data-common"

  def materialize(config) do
    %{
      "/namespace" => namespace(config)
    }
  end

  defp namespace(config) do
    namespace = DataSettings.public_namespace(config)

    B.build_resource(:namespace)
    |> B.name(namespace)
    |> B.app_labels(@app)
  end
end
