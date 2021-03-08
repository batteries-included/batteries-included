defmodule Server.Configs.PrometheusTest do
  use Server.DataCase

  alias Server.Configs.Prometheus

  test "base_config" do
    raw_config = Prometheus.base_config!()
    assert raw_config.path == "/prometheus/base"
  end
end
