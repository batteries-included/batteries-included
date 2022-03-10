defmodule ControlServer.ServiceConfigs do
  def default_services do
    Application.get_env(:control_server, :default_services, [])
  end
end
