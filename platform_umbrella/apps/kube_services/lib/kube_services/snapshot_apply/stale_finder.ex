defmodule KubeServices.SnapshotApply.StaleFinder do
  use GenServer

  alias KubeServices.SnapshotApply.Stale

  require Logger

  @me __MODULE__

  def start_link(opts \\ []) do
    delay = Keyword.get(opts, :delay, 3 * 60 * 1000)

    {:ok, pid} = result = GenServer.start_link(@me, %{delay: delay}, name: @me)

    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl true
  def init(initial_state) do
    {:ok, schedule(initial_state)}
  end

  @impl true
  def handle_info(:scan, state) do
    {:noreply, state |> scan() |> schedule()}
  end

  defp schedule(%{delay: delay} = state) do
    Process.send_after(self(), :scan, delay)
    state
  end

  defp scan(state) do
    KubeState.table_to_list()
    |> Enum.filter(&Stale.is_stale/1)
    |> log_scan_results()
    |> Enum.each(&KubeServices.ResourceDeleter.delete/1)

    state
  end

  defp log_scan_results(results) do
    Logger.info("Found #{length(results)} stale resources that can be deleted.")
  end
end
