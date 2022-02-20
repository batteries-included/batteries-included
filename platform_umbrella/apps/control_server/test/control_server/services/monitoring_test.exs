defmodule ControlServer.Services.MonitoringTest do
  use ControlServer.DataCase

  alias ControlServer.Services.RunnableService

  test "Activate" do
    assert RunnableService.active?(:prometheus_operator) == false
    assert RunnableService.active?(:prometheus) == false

    RunnableService.activate!(:prometheus)

    assert RunnableService.active?(:prometheus_operator)
    assert RunnableService.active?(:prometheus)
  end
end
