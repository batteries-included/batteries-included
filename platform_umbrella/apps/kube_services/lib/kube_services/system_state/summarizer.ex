defmodule KubeServices.SystemState.Summarizer do
  use GenServer
  use TypedStruct

  alias CommonCore.StateSummary
  alias KubeServices.KubeState

  require Logger

  @me __MODULE__
  @default_refresh_time 90 * 1000
  @state_opts [
    :refresh_time
  ]

  typedstruct module: State do
    field :refresh_time, integer(), default: 90_000
    field :should_refresh, bool(), default: true
    field :last, StateSummary.t()
  end

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

    state = %State{last: new_summary!(), refresh_time: sleep_time}
    _ref = schedule_refresh(state)
    {:ok, state}
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
  def handle_info(:refresh, %State{} = state) do
    _ref = schedule_refresh(state)

    {:noreply, %{state | last: new_summary!()}}
  end

  defp schedule_refresh(%State{should_refresh: true, refresh_time: refresh_time} = _state) do
    Process.send_after(self(), :refresh, refresh_time)
  end

  defp schedule_refresh(%State{should_refresh: _} = _state), do: nil

  @spec new_summary! :: StateSummary.t()
  defp new_summary! do
    with {:ok, res} <- ControlServer.SystemState.transaction(),
         kube_state <- KubeState.snapshot(),
         full <- Map.put(res, :kube_state, kube_state),
         summary <- struct(StateSummary, full),
         :ok <- EventCenter.SystemStateSummary.broadcast(summary) do
      summary
    end
  end
end
