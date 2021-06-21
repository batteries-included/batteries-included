defmodule ControlServerWeb.UsageReportController do
  use ControlServerWeb, :controller

  alias KubeUsage.Usage
  alias KubeUsage.Usage.UsageReport

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    usage_reports = Usage.list_usage_reports()
    render(conn, "index.json", usage_reports: usage_reports)
  end

  def create(conn, %{"usage_report" => usage_report_params}) do
    with {:ok, %UsageReport{} = usage_report} <- Usage.create_usage_report(usage_report_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.usage_report_path(conn, :show, usage_report))
      |> render("show.json", usage_report: usage_report)
    end
  end

  def show(conn, %{"id" => id}) do
    usage_report = Usage.get_usage_report!(id)
    render(conn, "show.json", usage_report: usage_report)
  end

  def update(conn, %{"id" => id, "usage_report" => usage_report_params}) do
    usage_report = Usage.get_usage_report!(id)

    with {:ok, %UsageReport{} = usage_report} <-
           Usage.update_usage_report(usage_report, usage_report_params) do
      render(conn, "show.json", usage_report: usage_report)
    end
  end

  def delete(conn, %{"id" => id}) do
    usage_report = Usage.get_usage_report!(id)

    with {:ok, %UsageReport{}} <- Usage.delete_usage_report(usage_report) do
      send_resp(conn, :no_content, "")
    end
  end
end
