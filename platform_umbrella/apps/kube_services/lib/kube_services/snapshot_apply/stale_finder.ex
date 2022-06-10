defmodule KubeServices.SnapshotApply.StaleFinder do
  use GenServer

  alias KubeServices.SnapshotApply.Stale

  require Logger

  @me __MODULE__

  def start_link(opts \\ []) do
    delay = Keyword.get(opts, :delay, 3 * 60 * 1000)
    enabled = Keyword.get(opts, :enabled, true)

    {:ok, pid} = result = GenServer.start_link(@me, %{delay: delay, enabled: enabled}, name: @me)

    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl true
  def init(initial_state) do
    {:ok, schedule(initial_state)}
  end

  @impl true
  def handle_info(:scan, state) do
    _res = state |> scan() |> delete(state)
    {:noreply, schedule(state)}
  end

  defp schedule(%{delay: delay} = state) do
    Process.send_after(self(), :scan, delay)
    state
  end

  defp scan(_state) do
    Stale.find_stale()
  end

  defp delete(resources, %{} = state) do
    if is_enabled(state) do
      Enum.each(resources, &KubeServices.ResourceDeleter.delete/1)
    else
      Logger.info("Skipping delete of #{length(resources)}")
    end

    state
  end

  defp is_enabled(%{enabled: enabled} = _state) do
    enabled
  end
end
