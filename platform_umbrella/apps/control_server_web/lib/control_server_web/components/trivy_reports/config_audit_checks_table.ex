defmodule ControlServerWeb.TrivyReports.ConfigAuditChecksTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonUI.Components.Table

  def config_audit_checks_table(assigns) do
    ~H"""
    <.table id="config-audit-checks-table" rows={@rows}>
      <:col :let={check} label="Check ID">{Map.get(check, "checkID", "")}</:col>
      <:col :let={check} label="Title">
        <.truncate_tooltip value={Map.get(check, "title", "")} />
      </:col>
      <:col :let={check} label="Category">
        <.truncate_tooltip value={Map.get(check, "category", "")} />
      </:col>
      <:col :let={check} label="Severity">
        <span class={severity_class(Map.get(check, "severity", ""))}>
          {Map.get(check, "severity", "")}
        </span>
      </:col>
      <:col :let={check} label="Status">
        <span class={status_class(Map.get(check, "success", false))}>
          {if Map.get(check, "success", false), do: "PASS", else: "FAIL"}
        </span>
      </:col>
      <:col :let={check} label="Description">
        <.truncate_tooltip value={Map.get(check, "description", "")} />
      </:col>
    </.table>
    """
  end

  defp severity_class("CRITICAL"), do: "badge badge-error"
  defp severity_class("HIGH"), do: "badge badge-error"
  defp severity_class("MEDIUM"), do: "badge badge-warning"
  defp severity_class("LOW"), do: "badge badge-info"
  defp severity_class(_), do: "badge badge-neutral"

  defp status_class(true), do: "badge badge-success"
  defp status_class(false), do: "badge badge-error"
end
