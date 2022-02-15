defmodule ControlServer.ServiceConfigs do
  def default_services do
    :control_server
    |> Application.get_env(ControlServer.Services)
    |> Keyword.get(:default_services, [])
  end
end
