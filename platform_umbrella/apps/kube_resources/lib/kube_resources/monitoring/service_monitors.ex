defmodule KubeResources.ServiceMonitors do
  alias ControlServer.Services
  alias ControlServer.Services.BaseService
  alias KubeResources.Grafana
  alias KubeResources.KubeState
  alias KubeResources.MonitoringSettings
  alias KubeResources.NodeExporter
  alias KubeResources.Prometheus
  alias KubeResources.PrometheusOperator

  def monitors do
    Enum.flat_map(Services.list_base_services(), &monitors/1)
  end

  def monitors(%BaseService{service_type: service_type, config: config}),
    do: monitors(service_type, config)

  def monitors(:monitoring, config) do
    PrometheusOperator.monitors(config) ++
      Prometheus.monitors(config) ++
      Grafana.monitors(config) ++
      NodeExporter.monitors(config) ++
      KubeState.monitors(config)
  end

  def monitors(_, _), do: []
end
