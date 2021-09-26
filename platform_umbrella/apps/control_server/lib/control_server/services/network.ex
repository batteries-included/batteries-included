defmodule ControlServer.Services.Network do
  alias ControlServer.Services

  @default_path "/network"

  def activate!(path \\ @default_path) do
    Services.find_or_create!(%{
      is_active: true,
      root_path: path,
      service_type: :network,
      config: default_config()
    })
  end

  def active?(path \\ @default_path), do: Services.active?(path)

  defp default_config do
    %{
      "kong.run" => kong_run?(),
      "nginx.run" => nginx_run?(),
      "istio.run" => istio_run?()
    }
  end

  defp kong_run? do
    :control_server
    |> Application.get_env(ControlServer.Services)
    |> Keyword.get(:kong_run, false)
  end

  defp nginx_run? do
    :control_server
    |> Application.get_env(ControlServer.Services)
    |> Keyword.get(:nginx_run, false)
  end

  defp istio_run? do
    :control_server
    |> Application.get_env(ControlServer.Services)
    |> Keyword.get(:istio_run, false)
  end
end
