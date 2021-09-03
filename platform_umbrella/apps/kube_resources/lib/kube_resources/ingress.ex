defmodule KubeResources.Ingress do
  alias ControlServer.Services
  alias ControlServer.Services.BaseService
  alias KubeResources.BatteryIngress
  alias KubeResources.MLIngress
  alias KubeResources.MonitoringIngress

  require Logger

  def materialize(_config) do
    Services.list_base_services()
    |> Enum.map(fn bs -> {"/ingress/base/#{bs.id}", base_service_ingress(bs)} end)
    |> Map.new()
  end

  def base_service_ingress(
        %BaseService{service_type: :monitoring, config: config} = _base_service
      ) do
    MonitoringIngress.ingress(config)
  end

  def base_service_ingress(%BaseService{service_type: :battery, config: config} = _base_service) do
    BatteryIngress.ingress(config)
  end

  def base_service_ingress(%BaseService{service_type: :ml, config: config} = _base_service) do
    MLIngress.ingress(config)
  end

  def base_service_ingress(_), do: []
end
