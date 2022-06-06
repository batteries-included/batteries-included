defmodule KubeServices.Usage.Poller do
  @moduledoc """
  Every once in a while poll and report current usage
  """
  use GenServer

  alias KubeServices.Usage.Report
  alias KubeServices.Usage.RestClient

  require Logger

  @period 5 * 60 * 1000
  @me __MODULE__

  defmodule State do
    defstruct [:client, :poll_period]
  end

  def start_link(opts) do
    {:ok, pid} = result = GenServer.start_link(@me, opts, name: @me)
    Logger.debug("#{@me} GenServer started with #{inspect(pid)}.")
    result
  end

  def init(args \\ []) do
    state = %State{
      client: Keyword.get_lazy(args, :client, fn -> RestClient.client() end),
      poll_period: Keyword.get(args, :poll_period, @period)
    }

    Process.send_after(self(), :poll, state.poll_period)
    {:ok, state}
  end

  def handle_info(:poll, %State{client: client, poll_period: period} = state) do
    Process.send_after(self(), :poll, period)

    with {:ok, report} <- create_report(),
         {:ok, db_report} <- store_report(report),
         {:ok, _result} <- send_report(client, db_report) do
      Logger.info(
        "UsagePoller nodes = #{report.num_nodes} pods = #{report.num_pods} report id = #{db_report.id}"
      )

      {:noreply, state}
    end
  end

  def create_report, do: Report.new()
  def store_report(report), do: Report.to_db(report)

  def send_report(nil = _client, _report), do: {:ok, nil}

  def send_report(client, report) do
    RestClient.report_usage(client, clean_home_report(report))
  end

  def clean_home_report(report) do
    report
    |> Map.from_struct()
    |> Enum.map(fn
      {:id, id} -> {:external_id, id}
      {:inserted_at, time} -> {:generated_at, time}
      {key, value} -> {key, value}
    end)
    |> Enum.into(%{})
    |> Map.drop([:updated_at, :__meta__])
  end
end
