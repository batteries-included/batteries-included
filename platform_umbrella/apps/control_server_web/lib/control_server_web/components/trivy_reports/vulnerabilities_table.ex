defmodule ControlServerWeb.TrivyReports.VulnerabilitiesTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonUI.Table

  def vulnerabilities_table(assigns) do
    ~H"""
    <.table rows={@rows}>
      <:col :let={vuln} label="Severity"><%= get_in(vuln, ~w(severity)) %></:col>
      <:col :let={vuln} label="Title">
        <.a href={get_in(vuln, ~w(primaryLink))}>
          <.truncate_tooltip value={get_in(vuln, ~w(title))} />
        </.a>
      </:col>
      <:col :let={vuln} label="Software">
        <.truncate_tooltip value={get_in(vuln, ~w(resource))} />
      </:col>
      <:col :let={vuln} label="Used"><%= get_in(vuln, ~w(installedVersion)) %></:col>
      <:col :let={vuln} label="Fixed"><%= get_in(vuln, ~w(fixedVersion)) %></:col>
      <:col :let={vuln} label="Extended Info">
        <.a href={get_in(vuln, ~w(primaryLink))} variant="external">
          Show
        </.a>
      </:col>
    </.table>
    """
  end
end
