defmodule ControlServer.Services.MonitoringTest do
  use ControlServer.DataCase

  alias ControlServer.Services.Monitoring

  test "Activate" do
    assert Monitoring.active?() == false

    Monitoring.activate!()

    assert Monitoring.active?()
  end
end
