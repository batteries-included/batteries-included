defmodule Server.Configs.PrometheusTest do
  use Server.DataCase

  alias Server.Configs.Prometheus
  alias Server.Configs.RawConfig

  test "create_for_cluster" do
    {:ok, %RawConfig{} = raw_config} = Prometheus.create()
    assert raw_config.path == "/prometheus/base"
  end

  test "base_config" do
    Prometheus.create()

    raw_config = Prometheus.base_config!()
    assert raw_config.path == "/prometheus/base"
  end
end
