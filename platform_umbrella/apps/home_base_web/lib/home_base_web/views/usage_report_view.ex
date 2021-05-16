defmodule HomeBaseWeb.UsageReportView do
  use HomeBaseWeb, :view
  alias HomeBaseWeb.UsageReportView

  def render("index.json", %{usage_reports: usage_reports}) do
    %{data: render_many(usage_reports, UsageReportView, "usage_report.json")}
  end

  def render("show.json", %{usage_report: usage_report}) do
    %{data: render_one(usage_report, UsageReportView, "usage_report.json")}
  end

  def render("usage_report.json", %{usage_report: usage_report}) do
    %{
      id: usage_report.id,
      namespace_report: usage_report.namespace_report,
      node_report: usage_report.node_report,
      reported_nodes: usage_report.reported_nodes,
      external_id: usage_report.external_id,
      generated_at: usage_report.generated_at
    }
  end
end
