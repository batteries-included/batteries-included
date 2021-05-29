defmodule ControlServerWeb.UsageReportView do
  use ControlServerWeb, :view
  alias ControlServerWeb.UsageReportView

  def render("index.json", %{usage_reports: usage_reports}) do
    %{data: render_many(usage_reports, UsageReportView, "usage_report.json")}
  end

  def render("show.json", %{usage_report: usage_report}) do
    %{data: render_one(usage_report, UsageReportView, "usage_report.json")}
  end

  def render("usage_report.json", %{usage_report: usage_report}) do
    %{
      id: usage_report.id,
      inserted_ad: usage_report.inserted_at,
      namespace_report: usage_report.namespace_report,
      node_report: usage_report.node_report,
      num_nodes: usage_report.num_nodes,
      num_pods: usage_report.num_pods
    }
  end
end
