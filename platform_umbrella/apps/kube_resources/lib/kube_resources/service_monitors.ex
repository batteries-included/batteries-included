defmodule KubeResources.ServiceMonitors do
  alias ControlServer.Services
  alias KubeExt.Builder, as: B
  alias KubeResources.DatabaseServiceMonitors
  alias KubeResources.KnativeOperator

  @spec materialize(map()) :: map()
  def materialize(%{} = _config) do
    Services.all_including_config()
    |> Enum.map(fn bs ->
      {"/monitors/#{bs.id}/#{bs.service_type}",
       bs.service_type
       |> monitors(bs.config)
       |> add_owner(bs)}
    end)
    |> Enum.reject(fn {_path, monitors} -> Enum.empty?(monitors) end)
    |> Enum.into(%{})
  end

  def add_owner(resources, base_service) when is_list(resources) do
    Enum.map(resources, fn r -> add_owner(r, base_service) end)
  end

  def add_owner(resource, base_service) when is_map(resource) do
    B.owner_label(resource, base_service.id)
  end

  def add_owner(resource, _), do: resource

  defp monitors(:database_internal, config), do: DatabaseServiceMonitors.internal_monitors(config)
  defp monitors(:database, config), do: DatabaseServiceMonitors.monitors(config)
  defp monitors(:knative, config), do: KnativeOperator.monitors(config)

  defp monitors(_, _), do: []
end
