defmodule KubeServices.SnapshotApply.Launcher do
  use GenServer

  require Logger

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{running: nil, started: nil, queue: []}, name: name)
  end

  def init(state) do
    {:ok, state}
  end

  def launch(launcher_target \\ __MODULE__, snapshot \\ nil) do
    GenServer.call(launcher_target, {:launch, snapshot})
  end

  def handle_call({:launch, snapshot}, _from, %{running: running} = state) do
    if running == nil do
      {pid, new_state} = do_launch(snapshot, state)
      {:reply, pid, new_state}
    else
      Logger.debug("Not launching still running #{inspect(running)}")
      {:reply, nil, state}
    end
  end

  def handle_info({:complete, snapshot}, state) do
    Logger.info("Snapshot apply complete result => #{inspect(snapshot)}")
    {_pid, new_state} = maybe_launch(%{state | running: nil})
    {:noreply, new_state}
  end

  def handle_info({:DOWN, pid, _, _object, reason}, state) do
    Logger.info("Agent #{inspect(pid)} crashed with reason #{reason}")
    {_pid, new_state} = maybe_launch(%{state | running: nil})
    {:noreply, new_state}
  end

  defp maybe_launch(%{queue: [head | rest]} = state) when not is_nil(head) do
    state = %{state | queue: rest || []}
    do_launch(head, state)
  end

  defp maybe_launch(state), do: {nil, state}

  defp do_launch(snapshot, state) do
    with {:ok, pid} <- KubeServices.SnapshotApply.Supervisor.start(snapshot, [self()]) do
      Process.monitor(pid)
      {pid, %{state | running: pid, started: DateTime.utc_now()}}
    end
  end
end
