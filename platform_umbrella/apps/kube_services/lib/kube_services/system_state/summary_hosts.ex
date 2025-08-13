defmodule KubeServices.SystemState.SummaryHosts do
  @moduledoc """
  This GenServer watches for the new system state
  summaries then caches some computed properties. These
  are then made available to the front end without
  having to compute a full system state snapshot.

  This genserver is responsible for host name computation

  - Forgejo Hostname
  - Grafana Hostname
  - Vmselect Hostname
  - Keycloak Hostname
  - Notebook Hostname

  It also hosts the ablity to compute a knative service hostname
  """

  use GenServer

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Hosts
  alias EventCenter.SystemStateSummary
  alias KubeServices.SystemState.Summarizer

  require Logger

  @me __MODULE__

  def start_link(opts) do
    {state_opts, genserver_opts} = Keyword.split(opts, [:summary])

    GenServer.start_link(@me, state_opts, Keyword.merge([name: @me], genserver_opts))
  end

  @impl GenServer
  def init(opts) do
    Logger.debug("Starting SummaryHosts")

    state = %{
      summary: Keyword.get_lazy(opts, :summary, &Summarizer.cached/0)
    }

    :ok = SystemStateSummary.subscribe()

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = message, state) do
    new_state = %{state | summary: message}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(method, _from, %{summary: summary} = state) when is_atom(method) do
    {:reply, apply(Hosts, method, [summary]), state}
  end

  @impl GenServer
  def handle_call([method | args], _from, %{summary: summary} = state) do
    {:reply, apply(Hosts, method, [summary | args]), state}
  end

  @spec control_host(GenServer.server()) :: String.t() | nil
  def control_host(target \\ @me) do
    GenServer.call(target, :control_host)
  end

  @spec forgejo_host(GenServer.server()) :: String.t() | nil
  def forgejo_host(target \\ @me) do
    GenServer.call(target, :forgejo_host)
  end

  @spec grafana_host(GenServer.server()) :: String.t() | nil
  def grafana_host(target \\ @me) do
    GenServer.call(target, :grafana_host)
  end

  @spec vmselect_host(GenServer.server()) :: String.t() | nil
  def vmselect_host(target \\ @me) do
    GenServer.call(target, :vmselect_host)
  end

  @spec vmagent_host(GenServer.server()) :: String.t() | nil
  def vmagent_host(target \\ @me) do
    GenServer.call(target, :vmagent_host)
  end

  @spec keycloak_host(GenServer.server()) :: String.t() | nil
  def keycloak_host(target \\ @me) do
    GenServer.call(target, :keycloak_host)
  end

  @spec keycloak_admin_host(GenServer.server()) :: String.t() | nil
  def keycloak_admin_host(target \\ @me) do
    GenServer.call(target, :keycloak_admin_host)
  end

  @spec notebooks_host(GenServer.server()) :: String.t() | nil
  def notebooks_host(target \\ @me) do
    GenServer.call(target, :notebooks_host)
  end

  @spec knative_host(GenServer.server(), map() | struct()) ::
          String.t() | nil
  def knative_host(target \\ @me, service) do
    GenServer.call(target, [:knative_host, service])
  end

  @spec traditional_host(GenServer.server(), map() | struct()) ::
          String.t() | nil
  def traditional_host(target \\ @me, service) do
    GenServer.call(target, [:traditional_host, service])
  end

  @spec kiali_host(GenServer.server()) :: String.t() | nil
  def kiali_host(target \\ @me) do
    GenServer.call(target, :kiali_host)
  end

  # NOTE: This isn't exclusive - some batteries don't have host mappings, some may have multiple in the future.
  # This should probably be revisited / revised in the future.
  @spec for_battery(GenServer.server(), atom()) :: String.t() | nil
  def for_battery(target \\ @me, battery_type) do
    GenServer.call(target, [:for_battery, battery_type])
  end
end
