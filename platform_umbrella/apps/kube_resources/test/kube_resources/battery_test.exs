defmodule KubeResources.BatteryTest do
  use ExUnit.Case

  alias KubeResources.Battery

  describe "Devtools workd from the BaseService" do
    test "Can materialize" do
      assert map_size(Battery.materialize(%{})) >= 5
    end
  end
end
