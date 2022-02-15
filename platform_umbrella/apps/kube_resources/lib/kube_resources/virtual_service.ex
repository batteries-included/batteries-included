defmodule KubeResources.VirtualService do
  alias ControlServer.Services

  alias KubeResources.ControlServerResources
  alias KubeResources.Grafana
  alias KubeResources.Notebooks
  alias KubeResources.Prometheus

  def materialize(config) do
    Services.list_base_services()
    |> Enum.map(fn bs ->
      {"/svcs/#{bs.id}", virtual_service(bs.service_type, config)}
    end)
    |> Map.new()
  end

  def virtual_service(:control_server, config),
    do: ControlServerResources.virtual_service(config)

  def virtual_service(:prometheus, config), do: Prometheus.virtual_service(config)
  def virtual_service(:grafana, config), do: Grafana.virtual_service(config)
  def virtual_service(:notebooks, config), do: Notebooks.virtual_service(config)

  def virtual_service(_, _config), do: []
end
