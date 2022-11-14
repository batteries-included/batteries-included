defmodule KubeResources.BatteryTest do
  use ExUnit.Case

  alias KubeResources.EchoServer
  alias KubeResources.ControlServer, as: ControlServerResources
  alias KubeExt.SystemState.StateSummary

  describe "Battery core services works" do
    test "Can materialize echo server" do
      assert map_size(EchoServer.materialize(%{config: %{}}, %StateSummary{})) >= 2
    end

    test "Can materialize control server" do
      assert map_size(ControlServerResources.materialize(%{config: %{}}, %StateSummary{})) >= 2
    end
  end
end
