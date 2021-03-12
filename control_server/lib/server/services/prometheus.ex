defmodule Server.Services.Prometheus do
  @moduledoc """
  Process for syncing the current db status with kubernetes.
  """
  use GenServer
  require Logger

  @impl true
  def init(_arg) do
    {:ok, nil}
  end

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def handle_cast({:sync, _cluster}, state) do
    Logger.debug("Starting prometheus sync")
    {:noreply, state}
  end

  def sync(%{} = cluster) do
    GenServer.cast(__MODULE__, {:sync, cluster})
  end
end
