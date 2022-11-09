defmodule KubeResources.ServiceMonitors do
  alias KubeExt.Builder, as: B
  alias KubeResources.DatabaseServiceMonitors
  alias KubeResources.KnativeOperator

  @spec materialize(any, any) :: map()
  def materialize(_battery, state) do
    state.system_batteries
    |> Enum.map(fn sys_battery ->
      {"/monitors/#{sys_battery.id}/#{sys_battery.type}",
       sys_battery.type
       |> monitors(sys_battery, state)
       |> add_owner(sys_battery)}
    end)
    |> Enum.reject(fn {_path, monitors} -> Enum.empty?(monitors) end)
    |> Enum.into(%{})
  end

  def add_owner(resources, %{} = battery) when is_list(resources) do
    Enum.map(resources, fn r -> add_owner(r, battery) end)
  end

  def add_owner(resource, %{} = battery) when is_map(resource) do
    B.owner_label(resource, battery.id)
  end

  def add_owner(resource, _), do: resource

  defp monitors(:database, battery, state), do: DatabaseServiceMonitors.monitors(battery, state)
  defp monitors(:knative, battery, state), do: KnativeOperator.monitors(battery, state)

  defp monitors(_, _, _), do: []
end
