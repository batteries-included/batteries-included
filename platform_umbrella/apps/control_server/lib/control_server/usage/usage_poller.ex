defmodule ControlServer.Usage.UsagePoller do
  @moduledoc """
  Everyonce in a while poll and report current usage
  """
  use GenServer

  require Logger

  alias ControlServer.Usage
  alias HomeBaseClient.EventCenter

  @period 5 * 60 * 1000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def init(_args \\ []) do
    Process.send_after(self(), :poll, @period)
    {:ok, []}
  end

  def handle_info(:poll, state) do
    with {:ok, report} <- Usage.create_usage_report() do
      Logger.info("Polling current usage found #{report.reported_nodes} report id = #{report.id}")

      with :ok <- EventCenter.broadcast(:usage_report, report |> prepare_usage()) do
        Process.send_after(self(), :poll, @period)
        {:noreply, state}
      end
    end
  end

  def prepare_usage(%Usage.UsageReport{} = usage_report) do
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
