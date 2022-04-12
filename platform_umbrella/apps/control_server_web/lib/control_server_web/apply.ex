defmodule ControlServerWeb.Apply do
  alias ControlServer.Services
  alias ControlServer.Services.RunnableService

  def apply_services(socket, prefix) do
    runnable_services = RunnableService.prefix(prefix)
    service_types = Enum.map(runnable_services, fn rs -> rs.service_type end)
    base_services = Services.from_service_types(service_types)

    Phoenix.LiveView.assign(socket,
      runnable_services: runnable_services,
      base_services: base_services
    )
  end
end
