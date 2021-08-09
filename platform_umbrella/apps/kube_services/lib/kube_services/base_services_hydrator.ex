defmodule KubeServices.BaseServicesHydrator do
  use GenServer

  alias ControlServer.Services
  alias ControlServer.Services.BaseService
  alias KubeServices.BaseServicesSupervisor
  alias KubeServices.Worker

  require Logger

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__, timeout: 10_000)
  end

  def init(args \\ []) do
    Logger.debug("Starting all base services")

    # Subscribe to all events.
    :ok = EventCenter.BaseService.subscribe()

    # Now get the service. Any base service shold
    # either be in the pubsub for insert or in this list.
    services = Services.list_base_services() ++ args
    Enum.each(services, &BaseServicesSupervisor.start_child/1)
    {:ok, services}
  end

  def handle_info({:insert, %BaseService{} = bs}, services) do
    with {:ok, _} <- BaseServicesSupervisor.start_child(bs) do
      {:noreply, [bs | services]}
    end
  end

  def handle_info({:delete, %BaseService{} = bs}, services) do
    with :ok <- Worker.finish(bs) do
      {:noreply, List.delete(services, bs)}
    end
  end

  def handle_info(_, services), do: {:noreply, services}
end
