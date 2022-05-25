defmodule KubeServices.SnapshotApply.TimedTrimer do
  use GenServer

  alias KubeServices.SnapshotApply.Trimer

  require Logger

  def start_link(opts \\ []) do
    delay = Keyword.get(opts, :delay, 3 * 60 * 1000)

    GenServer.start_link(__MODULE__, %{
      delay: delay
    })
  end

  def init(state) do
    {:ok, schedule(state)}
  end

  def handle_info(:trim, state) do
    Logger.debug("Time since last snapshot elapsed, Trimming")
    {:ok, _} = Trimer.trim()
    {:noreply, schedule(state)}
  end

  defp schedule(%{delay: delay} = state) do
    Process.send_after(self(), :trim, delay)
    state
  end
end
