defmodule ControlServer.ConfigGenerator do
  @moduledoc """
  Given any BaseService this will extract the kubernetes configs for application to the cluster.
  """

  alias ControlServer.Services.BaseService
  alias ControlServer.Services.Database
  alias ControlServer.Services.Monitoring

  def materialize(%BaseService{} = base_service) do
    case base_service.is_active do
      false ->
        %{}

      true ->
        materialize(base_service.service_type, base_service.config)
        |> Enum.map(fn {key, value} -> {base_service.root_path <> key, value} end)
        |> Map.new()
    end
  end

  defp materialize(:monitoring, %{} = config), do: Monitoring.materialize(config)
  defp materialize(:database, %{} = config), do: Database.materialize(config)
end
