defmodule KubeServices.PodLogs.Logger do
  @moduledoc """
  Handles the actual processing of log lines.

  Currently, just repeats them using `Logger.warning/2`
  """
  use GenServer
  require Logger

  def start_link(_init_args \\ []) do
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
