defmodule KubeResources.VirtualService do
  alias ControlServer.Services

  alias KubeResources.AlertManager
  alias KubeResources.ControlServerResources
  alias KubeResources.Gitea
  alias KubeResources.Grafana
  alias KubeResources.Notebooks
  alias KubeResources.Prometheus
  alias KubeResources.KialiServer

  def materialize(_config) do
    Services.all_including_config()
    |> Enum.map(fn bs ->
      {"/svcs/#{bs.id}/#{bs.service_type}", virtual_service(bs.service_type, bs.config)}
    end)
    |> Map.new()
  end

  def virtual_service(:control_server, config),
    do: ControlServerResources.virtual_service(config)

  def virtual_service(:prometheus, config), do: Prometheus.virtual_service(config)
  def virtual_service(:grafana, config), do: Grafana.virtual_service(config)
  def virtual_service(:alert_manager, config), do: AlertManager.virtual_service(config)
  def virtual_service(:notebooks, config), do: Notebooks.virtual_service(config)
  def virtual_service(:kiali, config), do: KialiServer.virtual_service(config)

  def virtual_service(:gitea, config) do
    [Gitea.virtual_service(config), Gitea.ssh_virtual_service(config)]
  end

  def virtual_service(_, _config), do: []
end
