defmodule ControlServerWeb.RBACReportTable do
  @moduledoc false
  use ControlServerWeb, :html

  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  alias ControlServerWeb.TrivyURL

  def cluster_rbac_reports_table(assigns) do
    ~H"""
    <.table
      id="cluster-rbac-table"
      rows={@reports}
      row_click={&JS.navigate(TrivyURL.report_url(&1))}
    >
      <:col :let={report} label="Name">{name(report)}</:col>
      <:col :let={report} label="Critical">
        {get_in(report, ~w(report summary criticalCount))}
      </:col>
      <:col :let={report} label="High">{get_in(report, ~w(report summary highCount))}</:col>
      <:action :let={report}>
        <.button
          variant="minimal"
          link={TrivyURL.report_url(report)}
          icon={:eye}
          id={"show_cluster_rbac_" <> name(report)}
        />
      </:action>
    </.table>
    """
  end

  def rbac_reports_table(assigns) do
    ~H"""
    <.table id="rbac-table" rows={@reports} row_click={&JS.navigate(TrivyURL.report_url(&1))}>
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
          id={"show_rbac_" <> name(report)}
        />
      </:action>
    </.table>
    """
  end
end
