defmodule KubeServices.SnapshotApply.TimedLauncher do
  use GenServer

  alias KubeServices.SnapshotApply.Launcher

  require Logger

  def start_link(opts \\ []) do
    delay = Keyword.get(opts, :delay, 180 * 1000)
    GenServer.start_link(__MODULE__, %{delay: delay, running: nil})
  end

  def init(state) do
    {:ok, schedule(state)}
  end

  def handle_info(:launch, state) do
    Logger.debug("Time since last snapshot elapsed, launching")
    Launcher.launch()
    {:noreply, schedule(state)}
  end

  defp schedule(%{delay: delay} = state) do
    running = Process.send_after(self(), :launch, delay)
    %{state | running: running}
  end
end
