defmodule ControlServer.Services.MonitoringTest do
  use ControlServer.DataCase

  alias ControlServer.Services

  test "Activate" do
    assert Services.PrometheusOperator.active?() == false
    assert Services.Prometheus.active?() == false

    Services.PrometheusOperator.activate!()
    Services.Prometheus.activate!()

    assert Services.Prometheus.active?()
  end
end
