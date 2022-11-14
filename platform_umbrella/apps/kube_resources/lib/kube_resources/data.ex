defmodule KubeResources.Data do
  alias KubeExt.Builder, as: B

  @app_name "data-common"

  def materialize(battery, state) do
    %{
      "/namespace" => namespace(battery, state)
    }
  end

  defp namespace(battery, _state) do
    B.build_resource(:namespace)
    |> B.name(battery.config.namespace)
    |> B.app_labels(@app_name)
  end
end
