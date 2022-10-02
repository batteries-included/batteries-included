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
    Logger.info("Got pubsub message Starting job #{job.id}", msg: msg, id: job.id)
    {:noreply, state}
  end
end
