defmodule KubeResources.Battery do
  @moduledoc false

  alias KubeResources.ControlServer
  alias KubeResources.EchoServer

  alias KubeRawResources.Battery, as: BatteryRaw

  def materialize(config) do
    config
    |> BatteryRaw.materialize()
    |> Map.merge(echo_server(config))
    |> Map.merge(control_server(config))
  end

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
end
