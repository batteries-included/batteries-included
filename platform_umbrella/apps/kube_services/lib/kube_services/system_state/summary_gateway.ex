defmodule KubeServices.SystemState.SummaryGateway do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.FromKubeState
  alias EventCenter.SystemStateSummary

  require Logger

  typedstruct module: State do
    field :http_routes, [map()], default: [], enforce: false
    field :tcp_routes, [map()], default: [], enforce: false
    field :gateways, [map()], default: [], enforce: false
    field :subscribe, boolean(), default: true, enforce: false
  end

  @me __MODULE__

  def start_link(opts) do
    {state_opts, genserver_opts} = opts |> Keyword.put_new(:name, @me) |> Keyword.split([:summary])
    GenServer.start_link(@me, state_opts, genserver_opts)
  end

  @impl GenServer
  def init(opts) do
    Logger.debug("Starting SummaryGateway")
    state = struct(State, opts)

    if state.subscribe do
      :ok = SystemStateSummary.subscribe()
    end

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = summary, state) do
    http_routes = FromKubeState.all_resources(summary, :gateway_http_route)
    tcp_routes = FromKubeState.all_resources(summary, :gateway_tcp_route)
    gateways = FromKubeState.all_resources(summary, :gateway)

    {:noreply,
     %{
       state
       | http_routes: http_routes,
         tcp_routes: tcp_routes,
         gateways: gateways
     }}
  end

  @impl GenServer
  def handle_call({:routes, limit}, _from, %State{http_routes: http_routes, tcp_routes: tcp_routes} = state) do
    {:reply, Enum.take(http_routes ++ tcp_routes, limit), state}
  end

  def handle_call({:http_routes, limit}, _from, %State{http_routes: http_routes} = state) do
    {:reply, Enum.take(http_routes, limit), state}
  end

  def handle_call({:tcp_routes, limit}, _from, %State{tcp_routes: tcp_routes} = state) do
    {:reply, Enum.take(tcp_routes, limit), state}
  end

  def handle_call({:gateways, limit}, _from, %State{gateways: gateways} = state) do
    {:reply, Enum.take(gateways, limit), state}
  end

  def routes(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:routes, limit})
  end

  def http_routes(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:http_routes, limit})
  end

  def tcp_routes(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:tcp_routes, limit})
  end

  def gateways(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:gateways, limit})
  end
end
