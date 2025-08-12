defmodule ControlServerWeb.ClusterInfraAssessmentReportTable do
  @moduledoc false
  use ControlServerWeb, :html

  import K8s.Resource.FieldAccessors, only: [name: 1]

  alias ControlServerWeb.TrivyURL

  def cluster_infra_assessment_reports_table(assigns) do
    ~H"""
    <.table
      id="cluster-infra-assessment-reports-table"
      rows={@reports}
      row_click={&JS.navigate(TrivyURL.report_url(&1))}
    >
      <:col :let={report} label="Name">{name(report)}</:col>
      <:col :let={report} label="Critical">
        {get_in(report, ~w(report summary criticalCount)) || 0}
      </:col>
      <:col :let={report} label="High">{get_in(report, ~w(report summary highCount)) || 0}</:col>
      <:col :let={report} label="Medium">{get_in(report, ~w(report summary mediumCount)) || 0}</:col>
      <:col :let={report} label="Low">{get_in(report, ~w(report summary lowCount)) || 0}</:col>
      <:col :let={report} label="Checks">
        {(get_in(report, ~w(report checks)) || []) |> length()}
      </:col>
      <:action :let={report}>
        <.button
          variant="minimal"
          link={TrivyURL.report_url(report)}
          icon={:eye}
          id={"show_cluster_infra_" <> name(report)}
        />

        <.tooltip target_id={"show_cluster_infra_" <> name(report)}>
          View Details
        </.tooltip>
      </:action>
    </.table>
    """
  end
end
