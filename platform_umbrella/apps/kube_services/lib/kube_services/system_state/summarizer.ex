defmodule KubeServices.SystemState.Summarizer do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.StateSummary
  alias KubeServices.KubeState
  alias KubeServices.SystemState.KeycloakSummarizer

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
  def new(target \\ @me), do: GenServer.call(target, :new, to_timeout(second: 90))

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

  defp get_db_state do
    {:ok, res} = ControlServer.SystemState.transaction()
    res
  end

  defp get_kube_state do
    KubeState.snapshot()
  end

  defp get_keycloak_state do
    KeycloakSummarizer.snapshot()
  end

  defp get_install_status do
    KubeServices.ET.InstallStatusWorker.get_status()
  end

  defp get_stable_versions do
    KubeServices.ET.StableVersionsWorker.get_stable_versions()
  end

  @spec new_summary! :: StateSummary.t()
  defp new_summary! do
    # Start a bunch of tasks
    # We need all of them before going on so speed this
    # up.
    tasks = [
      Task.async(&get_db_state/0),
      Task.async(&get_kube_state/0),
      Task.async(&get_keycloak_state/0),
      Task.async(&get_install_status/0),
      Task.async(&get_stable_versions/0)
    ]

    # Split the result list into something we can use
    [base_map, kube, keycloak, install_status, stable_versions_report] = Task.await_many(tasks)

    base = struct(StateSummary, base_map)

    summary = %{
      base
      | keycloak_state: keycloak,
        kube_state: kube,
        install_status: install_status,
        stable_versions_report: stable_versions_report,
        captured_at: DateTime.utc_now()
    }

    _ = EventCenter.SystemStateSummary.broadcast(summary)
    summary
  end
end
