defmodule KubeResources.ServiceMonitors do
  alias ControlServer.Services
  alias ControlServer.Services.BaseService
  alias KubeResources.DatabaseServiceMonitors
  alias KubeResources.MonitoringServiceMonitors
  alias KubeResources.NetworkServiceMonitors

  def monitors(_config) do
    Services.list_base_services() |> Enum.map(&do_monitors/1) |> Enum.into(%{})
  end

  defp do_monitors(
         %BaseService{service_type: service_type, config: service_config} = _base_service
       ),
       do: {"/monitors/#{service_type}", monitors(service_type, service_config)}

  defp monitors(:monitoring, config), do: MonitoringServiceMonitors.monitors(config)
  defp monitors(:network, config), do: NetworkServiceMonitors.monitors(config)
  defp monitors(:database, config), do: DatabaseServiceMonitors.monitors(config)

  defp monitors(_, _), do: []
end
