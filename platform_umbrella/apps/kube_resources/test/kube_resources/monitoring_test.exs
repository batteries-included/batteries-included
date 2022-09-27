defmodule KubeResources.MonitoringTest do
  use ControlServer.DataCase

  alias KubeResources.PrometheusOperator
  alias KubeResources.Prometheus
  alias KubeResources.Grafana

  describe "Materializing" do
    test "Materialize Prometheus Operator." do
      assert map_size(PrometheusOperator.materialize(%{})) >= 9
    end

    test "Materialize Prometheus" do
      assert map_size(Prometheus.materialize(%{})) >= 4
    end

    test "Materialize Grafana" do
      assert map_size(Grafana.materialize(%{})) >= 6
    end
  end
end
