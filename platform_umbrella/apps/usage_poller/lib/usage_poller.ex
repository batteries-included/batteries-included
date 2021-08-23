defmodule UsagePoller do
  @moduledoc """
  Every once in a while poll and report current usage
  """
  use GenServer

  alias KubeUsage.Usage
  alias UsagePoller.Report

  require Logger

  @period 1 * 60 * 1000

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
         {:ok, db_report} <- to_db(report),
         broadcast_report <- to_broadcast_report(db_report),
         :ok <- EventCenter.Usage.broadcast(:usage_report, broadcast_report) do
      Logger.info(
        "UsagePoller nodes = #{report.num_nodes} pods = #{report.num_pods} report id = #{db_report.id}"
      )

      {:noreply, state}
    end
  end

  def to_db(report) do
    report |> Map.from_struct() |> Usage.create_usage_report()
  end

  def to_broadcast_report(%Usage.UsageReport{} = usage_report) do
    usage_report
    |> Map.from_struct()
    |> Map.drop([:updated_at, :__meta__])
    |> Map.to_list()
    |> Enum.flat_map(fn
      {:inserted_at, dt} -> [{:generated_at, dt}]
      {:id, id} -> [{:external_id, id}]
      {key, value} -> [{key, value}]
    end)
    |> Map.new()
  end
end
