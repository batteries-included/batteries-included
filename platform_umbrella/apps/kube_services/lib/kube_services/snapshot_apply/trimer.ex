defmodule KubeServices.SnapshotApply.Trimer do
  use GenServer

  alias ControlServer.SnapshotApply

  require Logger

  @me __MODULE__

  defmodule State do
    defstruct [:keep]
  end

  def start_link(opts \\ []) do
    keep = Keyword.get(opts, :keep, days: 1)
    {:ok, pid} = result = GenServer.start_link(@me, %State{keep: keep}, name: @me)
    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  def trim(server \\ @me) do
    GenServer.call(server, :trim)
  end

  @impl true
  def handle_call(:trim, _from, %{keep: keep} = state) do
    keep_time = Timex.shift(Timex.now(), keep)

    with {number, _snapshots} <- SnapshotApply.trim_kube_snapshots(keep_time) do
      {:reply, {:ok, number}, state}
    end
  end
end
