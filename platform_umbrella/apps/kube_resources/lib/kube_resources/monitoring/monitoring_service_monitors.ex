defmodule KubeResources.MonitoringServiceMonitors do
  @moduledoc """
  This module contains the total of all the ServiceMonitors
   that the monitoring base service will need.

   This keeps KubeResources.ServiceMonitors from depening upon
   KubeServices.Monitoring which would create a loop. Most other BaseServices'
   will have the monitors method.
  """

  alias KubeResources.Grafana
  alias KubeResources.KubeState
  alias KubeResources.NodeExporter
  alias KubeResources.Prometheus
  alias KubeResources.PrometheusOperator

  def monitors(config) do
    PrometheusOperator.monitors(config) ++
      Prometheus.monitors(config) ++
      Grafana.monitors(config) ++
      NodeExporter.monitors(config) ++
      KubeState.monitors(config)
  end
end
