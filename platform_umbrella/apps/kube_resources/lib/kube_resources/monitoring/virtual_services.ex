defmodule KubeResources.Monitoring.VirtualServices do
  alias KubeResources.Grafana
  alias KubeResources.Prometheus

  def virtual_services(config) do
    [Grafana.virtual_service(config), Prometheus.virtual_service(config)]
  end
end
