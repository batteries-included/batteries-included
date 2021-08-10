defmodule KubeResources.ConfigGenerator do
  @moduledoc """
  Given any BaseService this will extract the kubernetes configs for application to the cluster.
  """

  alias ControlServer.Services.BaseService
  alias KubeResources.Battery
  alias KubeResources.Database
  alias KubeResources.Devtools
  alias KubeResources.Monitoring
  alias KubeResources.Network
  alias KubeResources.Security

  def materialize(%BaseService{} = base_service) do
    if base_service.is_active do
      base_service.config
      |> materialize(base_service.service_type)
      |> Enum.map(fn {key, value} -> {base_service.root_path <> key, value} end)
      |> Map.new()
    else
      %{}
    end
  end

  defp materialize(%{} = config, :monitoring), do: Monitoring.materialize(config)
  defp materialize(%{} = config, :database), do: Database.materialize(config)
  defp materialize(%{} = config, :security), do: Security.materialize(config)
  defp materialize(%{} = config, :devtools), do: Devtools.materialize(config)
  defp materialize(%{} = config, :network), do: Network.materialize(config)
  defp materialize(%{} = config, :battery), do: Battery.materialize(config)
end
