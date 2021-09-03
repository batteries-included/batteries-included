defmodule KubeResources.MonitoringIngress do
  alias KubeResources.Grafana
  alias KubeResources.Prometheus

  def ingress(config) do
    [
      Grafana.ingress(config),
      Prometheus.ingress(config)
    ]
  end
end
