defmodule KubeResources.MonitoringTest do
  use ControlServer.DataCase

  alias KubeResources.PrometheusOperator
  alias KubeResources.Prometheus
  alias KubeResources.Grafana

  alias KubeExt.SystemState.StateSummary

  describe "Materializing" do
    test "Materialize Prometheus Operator." do
      assert map_size(PrometheusOperator.materialize(%{config: %{}}, %StateSummary{})) >= 9
    end

    test "Materialize Prometheus" do
      assert map_size(Prometheus.materialize(%{config: %{}}, %StateSummary{})) >= 4
    end

    test "Materialize Grafana" do
      assert map_size(Grafana.materialize(%{config: %{}}, %StateSummary{})) >= 6
    end
  end
end
