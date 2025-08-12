defmodule ControlServerWeb.ExposedSecretReportTable do
  @moduledoc false
  use ControlServerWeb, :html

  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  alias ControlServerWeb.TrivyURL

  def exposed_secret_reports_table(assigns) do
    ~H"""
    <.table
      id="exposed-secret-reports-table"
      rows={@reports}
      row_click={&JS.navigate(TrivyURL.report_url(&1))}
    >
      <:col :let={report} label="Name">{name(report)}</:col>
      <:col :let={report} label="Namespace">{namespace(report)}</:col>
      <:col :let={report} label="Image">{get_in(report, ~w(report artifact repository))}</:col>
      <:col :let={report} label="Critical">
        {get_in(report, ~w(report summary criticalCount))}
      </:col>
      <:col :let={report} label="High">{get_in(report, ~w(report summary highCount))}</:col>
      <:col :let={report} label="Medium">{get_in(report, ~w(report summary mediumCount))}</:col>
      <:col :let={report} label="Low">{get_in(report, ~w(report summary lowCount))}</:col>
      <:action :let={report}>
        <.button
          variant="minimal"
          link={TrivyURL.report_url(report)}
          icon={:eye}
          id={"show_secret_" <> name(report) <> "__" <> namespace(report)}
        />

        <.tooltip target_id={"show_secret_" <> name(report) <> "__" <> namespace(report)}>
          View Details
        </.tooltip>
      </:action>
    </.table>
    """
  end
end
