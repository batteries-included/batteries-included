defmodule KubeServices.BaseServicesHydrator do
  use GenServer, restart: :transient

  alias ControlServer.Services
  alias KubeServices.BaseServicesSupervisor

  require Logger

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__, timeout: 10_000)
  end

  def init(_args) do
    Logger.debug("Starting all base services")
    Enum.each(Services.list_base_services(), &BaseServicesSupervisor.start_child/1)
    :ignore
  end
end
