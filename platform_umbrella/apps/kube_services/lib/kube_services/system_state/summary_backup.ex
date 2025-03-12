defmodule KubeServices.SystemState.SummaryBackup do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Backups
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
    Logger.debug("Starting SummaryBackup")

    opts = Keyword.put_new_lazy(opts, :summary, &Summarizer.cached/0)
    state = struct(State, opts)

    :ok = SystemStateSummary.subscribe()

    {:ok, state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = message, state) do
    new_state = %{state | summary: message}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call({:backups, cluster}, _from, %{summary: summary} = state) do
    {:reply, Backups.backups(summary, cluster), state}
  end

  def backups(target \\ @me) do
    GenServer.call(target, {:backups, nil})
  end

  def backups_for_cluster(target \\ @me, cluster) do
    GenServer.call(target, {:backups, cluster})
  end

  @spec sort(list(map()), :asc | :desc) :: list(map())
  def sort(backups, sorter \\ :asc), do: Enum.sort_by(backups, &get_in(&1, ~w(status startedAt)), sorter)
end
