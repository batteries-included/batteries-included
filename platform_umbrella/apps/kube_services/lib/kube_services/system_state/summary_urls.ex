defmodule KubeServices.SystemState.SummaryURLs do
  @moduledoc """
  This GenServer watches for the new system state summaries then caches some
  computed properties. These are then made available to the front end without
  having to compute a full system state snapshot.
  """

  use GenServer
  use TypedStruct

  alias CommonCore.StateSummary
  alias EventCenter.SystemStateSummary
  alias KubeServices.SystemState.Summarizer

  require Logger

  typedstruct module: State do
    field :summary, StateSummary.t(), default: nil, enforce: false
    field :subscribe, boolean(), default: true, enforce: false
  end

  @me __MODULE__

  def start_link(opts) do
    {state_opts, genserver_opts} = opts |> Keyword.put_new(:name, @me) |> Keyword.split([:summary])
    GenServer.start_link(@me, state_opts, genserver_opts)
  end

  @impl GenServer
  def init(opts) do
    Logger.debug("Starting SummaryURLs")

    opts = Keyword.put_new_lazy(opts, :summary, &Summarizer.cached/0)
    state = struct(State, opts)

    if state.subscribe, do: :ok = SystemStateSummary.subscribe()

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = message, state) do
    new_state = %{state | summary: message}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call([method | args], _from, %{summary: summary} = state) do
    {:reply, apply(CommonCore.StateSummary.URLs, method, [summary | args]), state}
  end

  @spec url_for_battery(atom | pid | {atom, any} | {:via, atom, any}, atom()) :: String.t() | nil
  def url_for_battery(target \\ @me, battery) do
    result = GenServer.call(target, [:uri_for_battery, battery])
    URI.to_string(result)
  end

  @spec keycloak_url_for_realm(atom | pid | {atom, any} | {:via, atom, any}, String.t()) :: String.t() | nil
  def keycloak_url_for_realm(target \\ @me, realm) do
    result = GenServer.call(target, [:keycloak_uri_for_realm, realm])
    URI.to_string(result)
  end
end
