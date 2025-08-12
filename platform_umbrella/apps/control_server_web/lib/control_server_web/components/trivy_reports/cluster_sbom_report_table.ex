defmodule ControlServerWeb.ClusterSBOMReportTable do
  @moduledoc false
  use ControlServerWeb, :html

  import K8s.Resource.FieldAccessors, only: [name: 1]

  alias ControlServerWeb.TrivyURL

  def cluster_sbom_reports_table(assigns) do
    ~H"""
    <.table
      id="cluster-sbom-reports-table"
      rows={@reports}
      row_click={&JS.navigate(TrivyURL.report_url(&1))}
    >
      <:col :let={report} label="Name">{name(report)}</:col>
      <:col :let={report} label="Image">{get_in(report, ~w(report artifact repository))}</:col>
      <:col :let={report} label="Components">
        {(get_in(report, ~w(report components components)) || []) |> length()}
      </:col>
      <:col :let={report} label="Format">{get_in(report, ~w(report components bomFormat))}</:col>
      <:action :let={report}>
        <.button
          variant="minimal"
          link={TrivyURL.report_url(report)}
          icon={:eye}
          id={"show_cluster_sbom_" <> name(report)}
        />

        <.tooltip target_id={"show_cluster_sbom_" <> name(report)}>
          View Details
        </.tooltip>
      </:action>
    </.table>
    """
  end
end
