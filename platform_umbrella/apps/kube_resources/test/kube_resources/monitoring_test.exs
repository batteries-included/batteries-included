defmodule KubeResources.MonitoringTest do
  use ExUnit.Case

  alias KubeResources.Monitoring

  describe "Materializing" do
    test "Materialize a simple config works." do
      assert map_size(Monitoring.materialize(%{})) >= 10
    end
  end
end
