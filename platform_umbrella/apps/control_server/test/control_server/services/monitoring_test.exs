defmodule ControlServer.Services.MonitoringTest do
  use ControlServer.DataCase

  alias ControlServer.Services.Monitoring

  describe "Services.Monitoring should generate good configs" do
    test "Materializing the default config" do
      config_map = Monitoring.materialize(Monitoring.default_config())
      assert_config_map_good(config_map)
    end
  end

  test "Activate and Deactivate" do
    assert Monitoring.active?() == false

    Monitoring.activate()

    assert Monitoring.active?()
  end
end
