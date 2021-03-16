defmodule Server.Services.Prometheus do
  @moduledoc """
  Process for syncing the current db status with kubernetes.
  """
  use GenServer
  require Logger

  @impl true
  def init(_arg) do
    {:ok, :starting}
  end

  def start_link(state, opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl true
  def handle_call(:status, _from, status) do
    {:reply, status, status}
  end

  @impl true
  def handle_call(:reset, _from, status) do
    {:reply, status, :starting}
  end

  @impl true
  def handle_cast({:sync, _cluster}, state) do
    Logger.debug("Starting prometheus sync")

    with {:ok, new_state} <- sync_operator(state) do
      Logger.info("Sync complete #{inspect(new_state)}")
      {:noreply, new_state}
    end
  end

  def sync_operator(:starting) do
    {:ok, :setup_complete}
  end

  def sync_operator(:setup_complete = status) do
    {:ok, status}
  end

  def sync_operator(_status) do
    {:error, :unknown_status}
  end

  def sync(name \\ __MODULE__, %{} = cluster) do
    GenServer.cast(name, {:sync, cluster})
  end

  def status(name \\ __MODULE__) do
    GenServer.call(name, :status)
  end
end
