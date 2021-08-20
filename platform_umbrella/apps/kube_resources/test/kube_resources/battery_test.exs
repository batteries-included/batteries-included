defmodule KubeResources.BatteryTest do
  use ControlServer.DataCase

  alias KubeResources.Battery

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(ControlServer.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(ControlServer.Repo, {:shared, self()})
    :ok
  end

  describe "Battery core services works from the BaseService" do
    test "Can materialize" do
      assert map_size(Battery.materialize(%{})) >= 5
    end
  end
end
