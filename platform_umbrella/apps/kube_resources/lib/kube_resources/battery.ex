defmodule KubeResources.Battery do
  @moduledoc false

  alias KubeResources.ControlServer
  alias KubeResources.EchoServer

  @bootstrapped_path "priv/manifests/battery/bootstrapped.yaml"

  def materialize(config) do
    %{
      "/0/bootstrapped" => yaml(bootstrapped_content()),
      "/1/deployment" => ControlServer.deployment(config),
      "/1/service" => ControlServer.service(config),
      "/2/echo/service" => EchoServer.service(config),
      "/2/echo/deployment" => EchoServer.deployment(config)
    }
  end

  defp bootstrapped_content, do: unquote(File.read!(@bootstrapped_path))

  defp yaml(content) do
    content
    |> YamlElixir.read_all_from_string!()
    |> Enum.map(&KubeExt.Hashing.decorate_content_hash/1)
  end
end
