defmodule KubeServices.SystemState.SummaryHosts do
  @moduledoc """
  This GenServer watches for the new system state
  summaries then caches some computed properties. These
  are then made available to the front end without
  having to compute a full system state snapshot.

  This genserver is responsible for host name computation

  - Gitea Hostname
  - Grafana Hostname
  - Vmselect Hostname
  - Harbor Hostname
  - Keycloak Hostname
  - Smtp4dev Hostname
  - Notebook Hostname

  It also hosts the ablity to compute a knative service hostname
  """

  use GenServer

  alias CommonCore.StateSummary
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
  def handle_call({:knative_host, service}, _from, %{summary: summary} = state) do
    {:reply, CommonCore.StateSummary.Hosts.knative_host(summary, service), state}
  end

  @impl GenServer
  def handle_call(method, _from, %{summary: summary} = state) when is_atom(method) do
    {:reply, apply(CommonCore.StateSummary.Hosts, method, [summary]), state}
  end

  @spec control_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def control_host(target \\ @me) do
    GenServer.call(target, :control_host)
  end

  @spec gitea_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def gitea_host(target \\ @me) do
    GenServer.call(target, :gitea_host)
  end

  @spec grafana_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def grafana_host(target \\ @me) do
    GenServer.call(target, :grafana_host)
  end

  @spec vmselect_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def vmselect_host(target \\ @me) do
    GenServer.call(target, :vmselect_host)
  end

  @spec vmagent_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def vmagent_host(target \\ @me) do
    GenServer.call(target, :vmagent_host)
  end

  @spec harbor_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def harbor_host(target \\ @me) do
    GenServer.call(target, :harbor_host)
  end

  @spec smtp4dev_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def smtp4dev_host(target \\ @me) do
    GenServer.call(target, :smtp4dev_host)
  end

  @spec keycloak_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def keycloak_host(target \\ @me) do
    GenServer.call(target, :keycloak_host)
  end

  @spec keycloak_admin_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def keycloak_admin_host(target \\ @me) do
    GenServer.call(target, :keycloak_admin_host)
  end

  @spec notebooks_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def notebooks_host(target \\ @me) do
    GenServer.call(target, :notebooks_host)
  end

  @spec knative_host(atom | pid | {atom, any} | {:via, atom, any}, map() | struct()) ::
          String.t() | nil
  def knative_host(target \\ @me, service) do
    GenServer.call(target, {:knative_host, service})
  end

  @spec kiali_host(atom | pid | {atom, any} | {:via, atom, any}) :: String.t() | nil
  def kiali_host(target \\ @me) do
    GenServer.call(target, :kiali_host)
  end
end
