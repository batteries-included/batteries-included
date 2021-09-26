defmodule KubeResources.VirtualService do
  alias ControlServer.Services
  alias ControlServer.Services.BaseService

  alias KubeResources.Battery
  alias KubeResources.ML
  alias KubeResources.Monitoring

  def materialize(_config) do
    Services.list_base_services()
    |> Enum.map(fn bs -> {"/istio/vitrual_services/#{bs.id}", virtual_services(bs)} end)
    |> Map.new()
  end

  def virtual_services(%BaseService{service_type: :battery, config: config}),
    do: Battery.VirtualServices.vitrual_services(config)

  def virtual_services(%BaseService{service_type: :monitoring, config: config}),
    do: Monitoring.VirtualServices.virtual_services(config)

  def virtual_services(%BaseService{service_type: :ml, config: config}),
    do: ML.VirtualServices.virtual_services(config)

  def virtual_services(_), do: []
end
