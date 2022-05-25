defmodule HomeBaseClient.Reporter do
  use GenServer

  require Logger

  defmodule State do
    @moduledoc """
    Inner state of HomeBaseClient
    """
    defstruct [:client]
  end

  def start_link(opts) do
    Logger.info("Start link for HomeBaseClient.Reporter")
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @impl true
  def init(_args) do
    client = HomeBaseClient.RestClient.client()
    :ok = EventCenter.Usage.subscribe()
    {:ok, %State{client: client}}
  end

  @impl true
  def handle_info({:usage_report, usage_report}, %State{client: client} = state) do
    Logger.info("XXXXXXXXXXXXXXXX -> #{inspect(usage_report)}")
    {:ok, result} = HomeBaseClient.RestClient.report_usage(client, Map.from_struct(usage_report))
    Logger.info("XXXXXXXXXXXXXXXX -> #{inspect(result)}")
    {:noreply, state}
  end

  @impl true
  def handle_info({_, _}, state) do
    {:noreply, state}
  end
end
