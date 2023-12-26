defmodule KubeServices.SystemState.SummaryBatteries do
  @moduledoc """
  This GenServer watches for the new system state
  summaries then caches some computed properties. These
  are then made available to the front end without
  having to compute a full system state snapshot.

  This genserver hosts the the installed batteries
  """
  use GenServer

  alias CommonCore.StateSummary
  alias EventCenter.SystemStateSummary
  alias KubeServices.SystemState.Summarizer

  require Logger

  @me __MODULE__

  def start_link(opts) do
    {state_opts, genserver_opts} = Keyword.split(opts, [:summary])

    {:ok, pid} =
      result = GenServer.start_link(@me, state_opts, Keyword.merge([name: @me], genserver_opts))

    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl GenServer
  def init(opts) do
    state = %{
      summary: Keyword.get_lazy(opts, :summary, &Summarizer.cached/0)
    }

    :ok = SystemStateSummary.subscribe()

    Logger.debug("Started SummaryBatteries Genserver with pid = #{inspect(self())}")

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = message, state) do
    new_state = %{state | summary: message}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(:installed_batteries, _from, %{summary: %StateSummary{batteries: batteries}} = state) do
    {:reply, Enum.sort_by(batteries, fn b -> b.type end), state}
  end

  @impl GenServer
  def handle_call(:installed_batteries, _from, state) do
    {:reply, [], state}
  end

  @impl GenServer
  def handle_call({:battery_installed, battery_type}, _from, %{summary: %StateSummary{batteries: batteries}} = state) do
    {:reply, Enum.any?(batteries, fn b -> b.type == battery_type end), state}
  end

  @impl GenServer
  def handle_call({:battery_installed, _battery_type}, _from, state) do
    {:reply, false, state}
  end

  def battery_installed(target \\ @me, battery_type) do
    GenServer.call(target, {:battery_installed, battery_type})
  end

  def installed_batteries(target \\ @me) do
    GenServer.call(target, :installed_batteries)
  end
end
