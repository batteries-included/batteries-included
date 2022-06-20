defmodule KubeServices.Usage.Worker do
  use Oban.Worker,
    max_attempts: 3

  alias KubeServices.Usage.Report
  alias KubeServices.Usage.RestClientGenserver

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{} = _args) do
    with {:ok, report} <- create_report(),
         {:ok, db_report} <- store_report(report),
         {:ok, _result} <- send_report(db_report) do
      Logger.info(
        "UsagePoller nodes = #{report.num_nodes} pods = #{report.num_pods} report id = #{db_report.id}"
      )

      :ok
    end
  end

  def create_report, do: Report.new()
  def store_report(report), do: Report.to_db(report)

  def send_report(report), do: RestClientGenserver.send_report(clean_home_report(report))

  def clean_home_report(report) do
    report
    |> Map.from_struct()
    |> Map.drop([:updated_at, :__meta__])
    |> Enum.map(fn
      {:id, id} -> {:external_id, id}
      {:inserted_at, time} -> {:generated_at, time}
      {key, value} -> {key, value}
    end)
    |> Enum.into(%{})
  end
end
