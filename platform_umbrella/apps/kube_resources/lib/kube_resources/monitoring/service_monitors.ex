defmodule KubeResources.ServiceMonitors do
  alias ControlServer.Services
  alias ControlServer.Services.BaseService
  alias KubeResources.MonitoringServiceMonitors
  alias KubeResources.NetworkServiceMonitors

  def monitors do
    Enum.flat_map(Services.list_base_services(), &monitors/1)
  end

  def monitors(%BaseService{service_type: service_type, config: config}),
    do: monitors(service_type, config)

  def monitors(:monitoring, config), do: MonitoringServiceMonitors.monitors(config)
  def monitors(:network, config), do: NetworkServiceMonitors.monitors(config)

  def monitors(_, _), do: []
end
