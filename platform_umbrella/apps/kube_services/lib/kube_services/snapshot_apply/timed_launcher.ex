defmodule KubeServices.SnapshotApply.TimedLauncher do
  use GenServer

  alias KubeServices.SnapshotApply.Launcher

  require Logger

  def start_link(opts \\ []) do
    delay = Keyword.get(opts, :delay, 300 * 1000)
    failing_delay = Keyword.get(opts, :failing_delay, 10 * 1000)

    GenServer.start_link(__MODULE__, %{
      delay: delay,
      failing_delay: failing_delay,
      status: :success,
      running: nil
    })
  end

  def init(state) do
    {:ok, schedule(state)}
  end

  def handle_info(:launch, state) do
    Logger.debug("Time since last snapshot elapsed, launching")
    Launcher.launch()
    {:noreply, schedule(state)}
  end

  defp schedule(state) do
    running = Process.send_after(self(), :launch, delay_time(state))
    %{state | running: running}
  end

  defp delay_time(%{status: :success, delay: delay}), do: delay
  defp delay_time(%{status: _, failing_delay: delay}), do: delay
end
