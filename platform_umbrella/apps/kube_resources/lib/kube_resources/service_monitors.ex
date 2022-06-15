defmodule KubeResources.ServiceMonitors do
  alias ControlServer.Services
  alias KubeExt.Builder, as: B
  alias KubeRawResources.IstioIstiod
  alias KubeResources.DatabaseServiceMonitors
  alias KubeResources.Grafana
  alias KubeResources.KnativeOperator
  alias KubeResources.KubeMonitoring
  alias KubeResources.Prometheus
  alias KubeResources.PrometheusOperator

  def materialize(_config) do
    Services.all_including_config()
    |> Enum.map(fn bs ->
      {"/monitors/#{bs.id}/#{bs.service_type}",
       bs.service_type
       |> monitors(bs.config)
       |> add_owner(bs)}
    end)
    |> Enum.reject(fn {_path, monitors} -> Enum.empty?(monitors) end)
    |> Enum.into(%{})
  end

  def add_owner(resources, base_service) when is_list(resources) do
    Enum.map(resources, fn r -> add_owner(r, base_service) end)
  end

  def add_owner(resource, base_service) when is_map(resource) do
    B.owner_label(resource, base_service.id)
  end

  def add_owner(resource, _), do: resource

  defp monitors(:prometheus, config), do: Prometheus.monitors(config)
  defp monitors(:promethues_operator, config), do: PrometheusOperator.monitors(config)
  defp monitors(:grafana, config), do: Grafana.monitors(config)
  defp monitors(:kube_monitoring, config), do: KubeMonitoring.monitors(config)
  defp monitors(:database_internal, config), do: DatabaseServiceMonitors.internal_monitors(config)
  defp monitors(:database, config), do: DatabaseServiceMonitors.monitors(config)
  defp monitors(:istio, config), do: IstioIstiod.monitors(config)
  defp monitors(:knative, config), do: KnativeOperator.monitors(config)

  defp monitors(_, _), do: []
end
