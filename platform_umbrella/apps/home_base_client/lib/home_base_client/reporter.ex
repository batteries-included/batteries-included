defmodule HomeBaseClient.Reporter do
  use GenServer

  defmodule State do
    @moduledoc """
    Inner state of HomeBaseClient
    """
    defstruct [:client]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @impl true
  def init(_args) do
    client = HomeBaseClient.RestClient.client()
    HomeBaseClient.EventCenter.subscribe()
    {:ok, %State{client: client}}
  end

  @impl true
  def handle_info({:usage_report, usage_report}, state) do
    state.client |> HomeBaseClient.RestClient.report_usage(usage_report)
    {:noreply, state}
  end

  @impl true
  def handle_info({_, _}, state) do
    {:noreply, state}
  end
end
