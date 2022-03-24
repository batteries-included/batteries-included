defmodule KubeResources.ServiceMonitors do
  alias ControlServer.Services
  # alias KubeRawResources.Istio
  alias KubeResources.DatabaseServiceMonitors
  alias KubeResources.Grafana
  alias KubeResources.Kong
  alias KubeResources.KubeMonitoring
  alias KubeResources.Prometheus
  alias KubeResources.PrometheusOperator

  def materialize(_config) do
    Services.list_base_services()
    |> Enum.map(fn bs ->
      {"/monitors/#{bs.id}/#{bs.service_type}", monitors(bs.service_type, bs.config)}
    end)
    |> Enum.into(%{})
  end

  defp monitors(:prometheus, config), do: Prometheus.monitors(config)
  defp monitors(:promethues_operator, config), do: PrometheusOperator.monitors(config)
  defp monitors(:grafana, config), do: Grafana.monitors(config)
  defp monitors(:kube_monitoring, config), do: KubeMonitoring.monitors(config)
  defp monitors(:database_internal, config), do: DatabaseServiceMonitors.internal_monitors(config)
  defp monitors(:database, config), do: DatabaseServiceMonitors.monitors(config)
  defp monitors(:kong, config), do: Kong.monitors(config)
  # defp monitors(:istio, config), do: Istio.monitors(config)

  defp monitors(_, _), do: []
end
