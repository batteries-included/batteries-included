defmodule KubeServices.Usage.RestClientGenserver do
  use GenServer

  alias KubeServices.Usage.RestClient

  require Logger

  @me __MODULE__

  defmodule State do
    defstruct [:client]
  end

  def start_link(opts) do
    {:ok, pid} = result = GenServer.start_link(@me, opts, name: @me)
    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  def init(args) do
    state = %State{
      client: Keyword.get_lazy(args, :client, fn -> RestClient.client() end)
    }

    {:ok, state}
  end

  def handle_call({:send_report, report}, _from, %State{client: client} = state) do
    {:reply, RestClient.report_usage(client, report), state}
  end

  @spec send_report(map()) :: {:error, any} | {:ok, Tesla.Env.t()}
  def send_report(report) do
    GenServer.call(@me, {:send_report, report})
  end
end
