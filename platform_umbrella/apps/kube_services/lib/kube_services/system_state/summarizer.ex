defmodule KubeServices.SystemState.Summarizer do
  use GenServer

  alias CommonCore.StateSummary

  require Logger

  @me __MODULE__
  @default_refresh_time 90 * 1000
  @state_opts [
    :refresh_time
  ]

  @spec new(atom | pid | {atom, any} | {:via, atom, any}) :: StateSummary.t()
  def new(target \\ @me), do: GenServer.call(target, :new)
  @spec cached(atom | pid | {atom, any} | {:via, atom, any}) :: StateSummary.t()
  def cached(target \\ @me), do: GenServer.call(target, :cached)
  @spec cached_field(atom | pid | {atom, any} | {:via, atom, any}, atom) :: any
  def cached_field(target \\ @me, field), do: GenServer.call(target, {:cached, field})

  @spec start_link(keyword) :: {:ok, pid}
  def start_link(opts) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    {:ok, pid} = result = GenServer.start_link(@me, state_opts, gen_opts)
    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl GenServer
  def init(opts) do
    sleep_time = Keyword.get(opts, :refresh_time, @default_refresh_time)

    schedule_refresh(sleep_time)
    {:ok, %{last: new_summary!(), refresh_time: sleep_time}}
  end

  @impl GenServer
  def handle_call(:new, _from, state) do
    new_summary = new_summary!()
    {:reply, new_summary, %{state | last: new_summary}}
  end

  @impl GenServer
  def handle_call(:cached, _from, %{last: cached} = state) do
    {:reply, cached, state}
  end

  @impl GenServer
  def handle_call({:cached, field}, _from, %{last: cached} = state) do
    {:reply, Map.get(cached, field), state}
  end

  @impl GenServer
  def handle_info(:refresh, %{refresh_time: time} = state) do
    schedule_refresh(time)

    {:noreply, %{state | last: new_summary!()}}
  end

  defp schedule_refresh(refresh_time) do
    Process.send_after(self(), :refresh, refresh_time)
  end

  @spec new_summary! :: StateSummary.t()
  defp new_summary! do
    with {:ok, res} <- ControlServer.SystemState.transaction(),
         kube_state <- KubeExt.KubeState.snapshot(),
         full <- Map.put(res, :kube_state, kube_state),
         summary <- struct(StateSummary, full),
         :ok <- EventCenter.SystemStateSummary.broadcast(summary) do
      summary
    end
  end
end
