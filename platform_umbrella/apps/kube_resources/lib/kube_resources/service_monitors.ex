defmodule KubeResources.ServiceMonitors do
  alias ControlServer.Batteries
  alias ControlServer.Batteries.SystemBattery
  alias KubeExt.Builder, as: B
  alias KubeResources.DatabaseServiceMonitors
  alias KubeResources.KnativeOperator

  @spec materialize(map()) :: map()
  def materialize(%{} = _config) do
    Batteries.list_system_batteries()
    |> Enum.map(fn battery ->
      {"/monitors/#{battery.id}/#{battery.type}",
       battery.type
       |> monitors(battery.config)
       |> add_owner(battery)}
    end)
    |> Enum.reject(fn {_path, monitors} -> Enum.empty?(monitors) end)
    |> Enum.into(%{})
  end

  def add_owner(resources, %SystemBattery{} = battery) when is_list(resources) do
    Enum.map(resources, fn r -> add_owner(r, battery) end)
  end

  def add_owner(resource, %SystemBattery{} = battery) when is_map(resource) do
    B.owner_label(resource, battery.id)
  end

  def add_owner(resource, _), do: resource

  defp monitors(:database_internal, config), do: DatabaseServiceMonitors.internal_monitors(config)
  defp monitors(:database, config), do: DatabaseServiceMonitors.monitors(config)
  defp monitors(:knative, config), do: KnativeOperator.monitors(config)

  defp monitors(_, _), do: []
end
