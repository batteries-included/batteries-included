defmodule KubeServices.Usage.Poller do
  @moduledoc """
  Every once in a while poll and report current usage
  """
  use GenServer

  alias KubeServices.Usage.Report

  require Logger

  @period 5 * 60 * 1000

  def start_link(opts) do
    Logger.info("Start link for UsagePoller")
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def init(args \\ []) do
    Process.send_after(self(), :poll, @period)
    {:ok, args}
  end

  def handle_info(:poll, state) do
    Process.send_after(self(), :poll, @period)

    with {:ok, report} <- Report.new(),
         {:ok, db_report} <- Report.to_db(report),
         :ok <- EventCenter.Usage.broadcast(:usage_report, report) do
      Logger.info(
        "UsagePoller nodes = #{report.num_nodes} pods = #{report.num_pods} report id = #{db_report.id}"
      )

      {:noreply, state}
    end
  end
end
