defmodule KubeResources.VirtualService do
  alias KubeExt.Builder, as: B

  alias ControlServer.Services

  alias KubeResources.ControlServerResources
  alias KubeResources.Gitea
  alias KubeResources.Notebooks
  alias KubeResources.Kiali
  alias KubeResources.TektonDashboard
  alias KubeResources.Harbor
  alias KubeResources.Prometheus
  alias KubeResources.Grafana
  alias KubeResources.Alertmanager

  def materialize(_config) do
    Services.all_including_config()
    |> Enum.map(fn bs ->
      {"/svcs/#{bs.id}/#{bs.service_type}",
       bs.service_type
       |> virtual_service(bs.config)
       |> add_owner(bs)}
    end)
    |> Enum.reject(fn {_path, virtual_services} ->
      virtual_services == nil || Enum.empty?(virtual_services)
    end)
    |> Enum.into(%{})
  end

  def add_owner(resources, base_service) when is_list(resources) do
    Enum.map(resources, fn r -> add_owner(r, base_service) end)
  end

  def add_owner(resource, base_service) when is_map(resource) do
    B.owner_label(resource, base_service.id)
  end

  def add_owner(resource, _), do: resource

  def virtual_service(:control_server, config),
    do: ControlServerResources.virtual_service(config)

  def virtual_service(:prometheus, config), do: Prometheus.virtual_service(config)
  def virtual_service(:grafana, config), do: Grafana.virtual_service(config)
  def virtual_service(:alert_manager, config), do: Alertmanager.virtual_service(config)
  def virtual_service(:notebooks, config), do: Notebooks.virtual_service(config)
  def virtual_service(:kiali, config), do: Kiali.virtual_service(config)
  def virtual_service(:tekton_dashboard, config), do: TektonDashboard.virtual_service(config)

  def virtual_service(:harbor, config) do
    [Harbor.virtual_service(config)]
  end

  def virtual_service(:gitea, config) do
    [Gitea.virtual_service(config), Gitea.ssh_virtual_service(config)]
  end

  def virtual_service(_, _config), do: []
end
