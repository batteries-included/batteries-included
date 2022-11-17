defmodule KubeResources.BatteryTest do
  use ExUnit.Case

  alias KubeResources.EchoServer
  alias KubeResources.ControlServer, as: ControlServerResources
  alias KubeExt.SystemState.StateSummary
  alias KubeExt.Defaults

  describe "Battery core services works" do
    test "Can materialize echo server" do
      assert map_size(EchoServer.materialize(echo_batery(), %StateSummary{})) >= 2
    end

    test "Can materialize control server" do
      assert map_size(ControlServerResources.materialize(control_battery(), %StateSummary{})) >= 2
    end
  end

  defp echo_batery do
    %{config: %{}}
  end

  defp control_battery do
    %{
      config: %{
        image: Defaults.Images.control_server_image(),
        secret_key: Defaults.random_key_string()
      }
    }
  end
end
