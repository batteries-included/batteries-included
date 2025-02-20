defmodule KubeServices.SystemState.SummaryIstio do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.FromKubeState
  alias EventCenter.SystemStateSummary

  require Logger

  typedstruct module: State do
    field :virtual_services, [map()], default: [], enforce: false
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
    Logger.debug("Starting SummaryIstio")
    state = struct(State, opts)

    if state.subscribe do
      :ok = SystemStateSummary.subscribe()
    end

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = summary, state) do
    virtual_services = FromKubeState.all_resources(summary, :istio_virtual_service)
    gateways = FromKubeState.all_resources(summary, :istio_gateway)

    {:noreply,
     %{
       state
       | virtual_services: virtual_services,
         gateways: gateways
     }}
  end

  @impl GenServer
  def handle_call({:virtual_services, limit}, _from, %State{virtual_services: virtual_services} = state) do
    {:reply, Enum.take(virtual_services, limit), state}
  end

  def handle_call({:gateways, limit}, _from, %State{gateways: gateways} = state) do
    {:reply, Enum.take(gateways, limit), state}
  end

  def virtual_services(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:virtual_services, limit})
  end

  def gateways(target \\ @me, limit \\ 7) do
    GenServer.call(target, {:gateways, limit})
  end
end
