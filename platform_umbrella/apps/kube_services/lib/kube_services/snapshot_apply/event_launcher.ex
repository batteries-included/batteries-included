defmodule KubeServices.SnapshotApply.EventLauncher do
  use GenServer

  alias KubeServices.SnapshotApply.CreationWorker

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Enum.each(EventCenter.Database.allowed_sources(), &EventCenter.Database.subscribe/1)
    {:ok, state}
  end

  def handle_info(msg, state) do
    job = CreationWorker.start!(schedule_in: 1)
    Logger.debug("Got pubsub message #{inspect(msg)} Starting job #{job.id}")
    {:noreply, state}
  end
end
