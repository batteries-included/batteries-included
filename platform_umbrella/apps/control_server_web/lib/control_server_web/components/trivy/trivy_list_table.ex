defmodule ControlServerWeb.Trivy.TrivyListTable do
  @moduledoc """
  Unified table component for listing Trivy reports in index pages.

  This component handles all types of Trivy report listing with configurable
  columns and proper navigation to detail pages.
  """
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors, only: [name: 1, namespace: 1]

  alias ControlServerWeb.TrivyURL

  def trivy_list_table(assigns) do
    ~H"""
    <.table
      id={@id}
      rows={@reports}
      row_click={&JS.navigate(TrivyURL.report_url(&1))}
    >
      <:col :let={report} :if={:name in @columns} label="Name">
        {name(report)}
      </:col>
      <:col :let={report} :if={:namespace in @columns} label="Namespace">
        {namespace(report)}
      </:col>
      <:col :let={report} :if={:image in @columns} label="Image">
        {get_in(report, ~w(report artifact repository))}
      </:col>
      <:col :let={report} :if={:critical in @columns} label="Critical">
        {get_in(report, ~w(report summary criticalCount)) || 0}
      </:col>
      <:col :let={report} :if={:high in @columns} label="High">
        {get_in(report, ~w(report summary highCount)) || 0}
      </:col>
      <:col :let={report} :if={:medium in @columns} label="Medium">
        {get_in(report, ~w(report summary mediumCount)) || 0}
      </:col>
      <:col :let={report} :if={:low in @columns} label="Low">
        {get_in(report, ~w(report summary lowCount)) || 0}
      </:col>
      <:col :let={report} :if={:checks in @columns} label="Checks">
        {(get_in(report, ~w(report checks)) || []) |> length()}
      </:col>
      <:col :let={report} :if={:secrets in @columns} label="Secrets">
        {(get_in(report, ~w(report secrets)) || []) |> length()}
      </:col>
      <:col :let={report} :if={:components in @columns} label="Components">
        {(get_in(report, ~w(report components components)) || []) |> length()}
      </:col>
      <:action :let={report}>
        <.button
          variant="minimal"
          link={TrivyURL.report_url(report)}
          icon={:eye}
          id={action_button_id(report)}
        />

        <.tooltip target_id={action_button_id(report)}>
          View Details
        </.tooltip>
      </:action>
    </.table>
    """
  end

  defp action_button_id(report) do
    report_name = name(report)
    report_namespace = namespace(report)

    if report_namespace do
      "show_#{report_name}__#{report_namespace}"
    else
      "show_#{report_name}"
    end
  end
end
