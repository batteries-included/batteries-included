defmodule KubeResources.MonitoringTest do
  use ExUnit.Case

  alias KubeResources.PrometheusOperator
  alias KubeResources.Prometheus
  alias KubeResources.Grafana

  alias KubeExt.SystemState.StateSummary
  alias KubeExt.Defaults.Catalog

  describe "Materializing" do
    test "Materialize Prometheus Operator." do
      assert map_size(
               PrometheusOperator.materialize(Catalog.get(:prometheus_operator), %StateSummary{})
             ) >= 9
    end

    test "Materialize Prometheus" do
      assert map_size(Prometheus.materialize(Catalog.get(:prometheus), %StateSummary{})) >= 4
    end

    test "Materialize Grafana" do
      assert map_size(Grafana.materialize(Catalog.get(:grafana), %StateSummary{})) >= 6
    end
  end
end
