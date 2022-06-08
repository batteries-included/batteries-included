defmodule KubeServices.SnapshotApply.EventLauncher do
  use GenServer

  alias KubeServices.SnapshotApply.Launcher

  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Enum.each(EventCenter.Database.allowed_sources(), &EventCenter.Database.subscribe/1)
    {:ok, state}
  end

  def handle_info(msg, state) do
    pid = Launcher.launch()
    Logger.debug("Got pubsub message #{inspect(msg)} Result pid = #{inspect(pid)}")
    {:noreply, state}
  end
end
