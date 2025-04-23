defmodule HomeBaseWeb.Admin.UsageReportsTable do
  @moduledoc false
  use HomeBaseWeb, :html

  alias CommonCore.ET.NamespaceReport

  attr :rows, :list, default: []

  def usage_reports_table(assigns) do
    ~H"""
    <.table id="stored_usage_reports-table" rows={@rows}>
      <:col :let={report} label="Inserted At"><.relative_display time={report.inserted_at} /></:col>
      <:col :let={report} label="Nodes">
        {(report.report.node_report.pod_counts || %{}) |> map_size()}
      </:col>
      <:col :let={report} label="Pods">
        {NamespaceReport.pod_count(report.report.namespace_report)}
      </:col>
      <:col :let={report} label="Postgres Clusters">
        {map_size(report.report.postgres_report.instance_counts)}
      </:col>
      <:col :let={report} label="Redis Instances">
        {map_size(report.report.redis_report.instance_counts)}
      </:col>
      <:col :let={report} label="Knative Services">
        {map_size(report.report.knative_report.pod_counts)}
      </:col>
      <:col :let={report} label="Batteries">
        {(report.report.batteries || []) |> length()}
      </:col>
      <:col :let={report} label="Projects">
        {report.report.num_projects}
      </:col>
    </.table>
    """
  end
end
