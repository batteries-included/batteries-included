defmodule KubeResources.BatteryTest do
  use ControlServer.DataCase, async: false

  alias KubeResources.Battery

  describe "Battery core services works from the BaseService" do
    test "Can materialize" do
      assert map_size(Battery.materialize(%{})) >= 3
    end
  end
end
