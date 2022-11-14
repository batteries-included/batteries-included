defmodule KubeResources.VirtualService do
  alias KubeExt.Builder, as: B

  alias KubeResources.ControlServer, as: ControlServerResources
  alias KubeResources.Gitea
  alias KubeResources.Notebooks
  alias KubeResources.Kiali
  alias KubeResources.Harbor
  alias KubeResources.Prometheus
  alias KubeResources.Grafana
  alias KubeResources.Alertmanager

  def materialize(_battery, state) do
    state.batteries
    |> Enum.with_index()
    |> Enum.map(fn {sys_battery, idx} ->
      {virtual_service_path(sys_battery, idx),
       sys_battery
       |> virtual_service(state)
       |> add_owner(sys_battery)}
    end)
    |> Enum.reject(fn {_path, virtual_services} ->
      virtual_services == nil || Enum.empty?(virtual_services)
    end)
    |> Enum.into(%{})
  end

  defp virtual_service_path(%{id: id} = _battery, _idx), do: "/virtual_svcs/#{id}/"
  defp virtual_service_path(_battery, idx), do: "/virtual_svcs/#{idx}/idx/"

  def add_owner(resources, %{} = battery) when is_list(resources) do
    Enum.map(resources, fn r -> add_owner(r, battery) end)
  end

  def add_owner(resource, %{id: id} = _battery) when is_map(resource) do
    B.owner_label(resource, id)
  end

  def add_owner(resource, _), do: resource

  def virtual_service(%{type: :control_server} = battery, state),
    do: ControlServerResources.virtual_service(battery, state)

  def virtual_service(%{type: :prometheus} = battery, state),
    do: Prometheus.virtual_service(battery, state)

  def virtual_service(%{type: :grafana} = battery, state),
    do: Grafana.virtual_service(battery, state)

  def virtual_service(%{type: :alert_manager} = battery, state),
    do: Alertmanager.virtual_service(battery, state)

  def virtual_service(%{type: :notebooks} = battery, state),
    do: Notebooks.virtual_service(battery, state)

  def virtual_service(%{type: :kiali} = battery, state), do: Kiali.virtual_service(battery, state)

  def virtual_service(%{type: :harbor} = battery, state) do
    [Harbor.virtual_service(battery, state)]
  end

  def virtual_service(%{type: :gitea} = battery, state) do
    [Gitea.virtual_service(battery, state), Gitea.ssh_virtual_service(battery, state)]
  end

  def virtual_service(_battery, _state), do: nil
end
