defmodule KubeServices.SnapshotApply.EventLauncher do
  use GenServer

  alias KubeServices.SnapshotApply.Launcher
  alias EventCenter.BaseService

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    BaseService.subscribe()

    {:ok, state}
  end

  def handle_info(_msg, state) do
    Logger.debug("Got a pubsub message")
    Launcher.launch()
    {:noreply, state}
  end

end
