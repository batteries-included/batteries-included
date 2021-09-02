defmodule KubeResources.MonitoringTest do
  use ControlServer.DataCase

  alias KubeResources.Monitoring
  alias K8s.Resource

  defp contains_grafana(resources) when is_list(resources),
    do: Enum.any?(resources, &contains_grafana/1)

  defp contains_grafana(resource) do
    Resource.name(resource) == "grafana" && Resource.kind(resource) == "Deployment"
  end

  describe "Materializing" do
    test "Materialize a simple config works." do
      assert map_size(Monitoring.materialize(%{})) >= 10
    end

    test "contains some grafana deplpyment" do
      assert Enum.any?(Monitoring.materialize(%{}), fn {_k, resources} ->
               contains_grafana(resources)
             end)
    end
  end
end
