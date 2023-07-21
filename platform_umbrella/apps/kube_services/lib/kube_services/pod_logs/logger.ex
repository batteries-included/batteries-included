defmodule KubeServices.PodLogs.Logger do
  use GenServer
  require Logger

  def start_link(_init_args \\ []) do
    # you may want to register your server with `name: __MODULE__`
    # as a third argument to `start_link`
    GenServer.start_link(__MODULE__, [])
  end

  @impl GenServer
  def init(_args) do
    {:ok, :initial_state}
  end

  @impl GenServer
  def handle_info({:pod_log, line}, ctx) do
    Logger.warning(line)
    {:noreply, ctx}
  end
end
