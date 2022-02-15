defmodule KubeResources.MonitoringTest do
  use ControlServer.DataCase

  alias KubeResources.PrometheusOperator
  alias KubeResources.Prometheus
  alias KubeResources.Grafana
  alias K8s.Resource

  defp contains_grafana(resources) when is_list(resources),
    do: Enum.any?(resources, &contains_grafana/1)

  defp contains_grafana(resource) do
    Resource.name(resource) == "grafana" && Resource.kind(resource) == "Deployment"
  end

  describe "Materializing" do
    test "Materialize Prometheus Operator." do
      assert map_size(PrometheusOperator.materialize(%{})) >= 9
    end

    test "Materialize Prometheus" do
      assert map_size(Prometheus.materialize(%{})) >= 6
    end

    test "Materialize Grafana" do
      assert map_size(Grafana.materialize(%{})) >= 6
    end

    test "contains some grafana deplpyment" do
      assert Enum.any?(Grafana.materialize(%{}), fn {_k, resources} ->
               contains_grafana(resources)
             end)
    end
  end
end
