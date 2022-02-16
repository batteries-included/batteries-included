defmodule KubeResources.BatteryTest do
  use ControlServer.DataCase, async: false

  alias KubeResources.EchoServer
  alias KubeResources.ControlServerResources

  describe "Battery core services works from the BaseService" do
    test "Can materialize echo server" do
      assert map_size(EchoServer.materialize(%{})) >= 2
    end

    test "Can materialize control server" do
      assert map_size(ControlServerResources.materialize(%{})) >= 2
    end
  end
end
