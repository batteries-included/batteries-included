defmodule KubeServices.SystemState.SummaryBatteries do
  @moduledoc """
  This GenServer watches for the new system state
  summaries then caches some computed properties. These
  are then made available to the front end without
  having to compute a full system state snapshot.

  This genserver hosts the the installed batteries
  and their most important settings.
  """
  use GenServer

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.Core
  alias CommonCore.StateSummary.Namespaces
  alias CommonCore.StateSummary.SSL
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
  def handle_call({:installed_batteries, group}, _from, %{summary: %StateSummary{batteries: batteries}} = state) do
    {:reply,
     batteries
     |> Enum.filter(fn b -> group == nil or b.group == group end)
     |> Enum.sort_by(fn b -> b.type end), state}
  end

  @impl GenServer
  def handle_call(:installed_batteries, _from, state) do
    {:reply, [], state}
  end

  @impl GenServer
  def handle_call({:battery_installed, battery_type}, _from, %{summary: %StateSummary{batteries: batteries}} = state) do
    {:reply, Enum.any?(batteries, &Batteries.battery_matches_type(&1, battery_type)), state}
  end

  @impl GenServer
  def handle_call({:battery_installed, _battery_type}, _from, state) do
    {:reply, false, state}
  end

  @impl GenServer
  def handle_call(:core_battery, _from, %{summary: %StateSummary{} = summary} = state) do
    {:reply, Core.get_battery_core(summary), state}
  end

  @impl GenServer
  def handle_call(:default_size, _, %{summary: %StateSummary{} = summary} = state) do
    {:reply, Core.config_field(summary, :default_size) || :tiny, state}
  end

  @impl GenServer
  def handle_call(:ai_namespace, _from, %{summary: %StateSummary{} = summary} = state) do
    {:reply, Namespaces.ai_namespace(summary), state}
  end

  @impl GenServer
  def handle_call(:core_namespace, _from, %{summary: %StateSummary{} = summary} = state) do
    {:reply, Namespaces.core_namespace(summary), state}
  end

  @impl GenServer
  def handle_call(:knative_namespace, _from, %{summary: %StateSummary{} = summary} = state) do
    {:reply, Namespaces.knative_namespace(summary), state}
  end

  @impl GenServer
  def handle_call(:traditional_namespace, _from, %{summary: %StateSummary{} = summary} = state) do
    {:reply, Namespaces.traditional_namespace(summary), state}
  end

  @impl GenServer
  def handle_call(:ssl_enabled?, _from, %{summary: %StateSummary{} = summary} = state) do
    {:reply, SSL.ssl_enabled?(summary), state}
  end

  # Is the battery installed?
  #
  # @param target [pid] the pid of the genserver to query
  # @param battery_type [atom] the type of the battery to check
  def battery_installed(target \\ @me, battery_type) do
    GenServer.call(target, {:battery_installed, battery_type})
  end

  def installed_batteries(group \\ nil) do
    GenServer.call(@me, {:installed_batteries, group})
  end

  def installed_batteries(target, group) do
    GenServer.call(target, {:installed_batteries, group})
  end

  def core_battery(target \\ @me) do
    GenServer.call(target, :core_battery)
  end

  def default_size(target \\ @me) do
    GenServer.call(target, :default_size)
  end

  def ai_namespace(target \\ @me) do
    GenServer.call(target, :ai_namespace)
  end

  def core_namespace(target \\ @me) do
    GenServer.call(target, :core_namespace)
  end

  def knative_namespace(target \\ @me) do
    GenServer.call(target, :knative_namespace)
  end

  def traditional_namespace(target \\ @me) do
    GenServer.call(target, :traditional_namespace)
  end

  def ssl_enabled?(target \\ @me) do
    GenServer.call(target, :ssl_enabled?)
  end
end
