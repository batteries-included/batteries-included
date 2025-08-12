defmodule ControlServerWeb.ConfigAuditReportTable do
  @moduledoc false
  use ControlServerWeb, :html

  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  alias ControlServerWeb.TrivyURL

  def config_audit_reports_table(assigns) do
    ~H"""
    <.table
      id="config-audit-reports-table"
      rows={@reports}
      row_click={&JS.navigate(TrivyURL.report_url(&1))}
    >
      <:col :let={report} label="Name">{name(report)}</:col>
      <:col :let={report} label="Namespace">{namespace(report)}</:col>
      <:col :let={report} label="Critical">
        {get_in(report, ~w(report summary criticalCount))}
      </:col>
      <:col :let={report} label="High">{get_in(report, ~w(report summary highCount))}</:col>
      <:action :let={report}>
        <.button
          variant="minimal"
          link={TrivyURL.report_url(report)}
          icon={:eye}
          id={"show_config_audit_" <> name(report)}
        />
      </:action>
    </.table>
    """
  end
end
