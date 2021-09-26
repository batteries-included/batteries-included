defmodule KubeResources.Battery do
  @moduledoc false

  alias KubeResources.ControlServer
  alias KubeResources.EchoServer

  @bootstrapped_path "priv/manifests/battery/bootstrapped.yaml"

  def materialize(config) do
    %{
      "/0/bootstrapped" => crd(config)
    }
    |> Map.merge(echo_server(config))
    |> Map.merge(control_server(config))
  end

  def crd(_), do: yaml(bootstrapped_content())

  defp bootstrapped_content, do: unquote(File.read!(@bootstrapped_path))

  defp echo_server(config) do
    %{
      "/1/echo/service" => EchoServer.service(config),
      "/1/echo/deployment" => EchoServer.deployment(config)
    }
  end

  defp control_server(%{"control.run" => true} = config) do
    %{
      "/1/control_server/deployment" => ControlServer.deployment(config),
      "/1/control_server/service" => ControlServer.service(config)
    }
  end

  defp control_server(_config), do: %{}

  defp yaml(content) do
    content
    |> YamlElixir.read_all_from_string!()
    |> Enum.map(&KubeExt.Hashing.decorate_content_hash/1)
  end
end
