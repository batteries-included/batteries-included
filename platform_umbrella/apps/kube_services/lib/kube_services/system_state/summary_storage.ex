defmodule KubeServices.SystemState.SummaryStorage do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.KubeStorage
  alias EventCenter.SystemStateSummary
  alias KubeServices.SystemState.Summarizer

  require Logger

  typedstruct module: State do
    field :summary, map(), default: nil, enforce: false
  end

  @me __MODULE__
  def start_link(opts) do
    {state_opts, genserver_opts} = opts |> Keyword.put_new(:name, @me) |> Keyword.split([:summary])
    GenServer.start_link(@me, state_opts, genserver_opts)
  end

  @impl GenServer
  def init(opts) do
    Logger.debug("Starting SummaryStorage")

    opts = Keyword.put_new_lazy(opts, :summary, &Summarizer.cached/0)
    state = struct(State, opts)

    :ok = SystemStateSummary.subscribe()

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:storage_classes, _from, %{summary: summary} = state) do
    {:reply, KubeStorage.storage_classes(summary), state}
  end

  @impl GenServer
  def handle_call(:default_storage_class, _from, %{summary: summary} = state) do
    {:reply, KubeStorage.default_storage_class(summary), state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = message, state) do
    new_state = %{state | summary: message}
    {:noreply, new_state}
  end

  def storage_classes(target \\ @me) do
    GenServer.call(target, :storage_classes)
  end

  def default_storage_class(target \\ @me) do
    GenServer.call(target, :default_storage_class)
  end
end
