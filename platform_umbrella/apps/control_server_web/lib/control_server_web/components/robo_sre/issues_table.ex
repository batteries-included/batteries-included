defmodule ControlServerWeb.RoboSRE.IssuesTable do
  @moduledoc """
  Table component for displaying RoboSRE issues.
  """
  use ControlServerWeb, :html

  import ControlServerWeb.RoboSRE.IssueStatusBadge

  alias CommonCore.RoboSRE.IssueType

  attr :rows, :list, required: true
  attr :meta, :map, default: nil
  attr :abridged, :boolean, default: false

  def issues_table(assigns) do
    ~H"""
    <.table
      id="robo-sre-issues-table"
      variant={@meta && "paginated"}
      rows={@rows}
      meta={@meta}
      path={~p"/robo_sre/issues"}
      row_click={&JS.navigate(show_url(&1))}
    >
      <:col :let={issue} field={:subject} label="Subject">
        <.link navigate={show_url(issue)} class="hover:underline font-medium">
          {issue.subject}
        </.link>
      </:col>

      <:col :let={issue} field={:issue_type} label="Type">
        <.badge minimal label={IssueType.label(issue.issue_type)} />
      </:col>

      <:col :let={issue} field={:status} label="Status">
        <.issue_status_badge status={issue.status} />
      </:col>

      <:col :let={issue} :if={!@abridged} field={:handler} label="Handler">
        <span :if={issue.handler} class="text-sm text-gray-dark">
          {handler_label(issue.handler)}
        </span>
        <span :if={!issue.handler} class="text-sm text-gray-light">
          Not assigned
        </span>
      </:col>

      <:col :let={issue} field={:updated_at} label="Updated">
        <.relative_display time={issue.updated_at} />
      </:col>

      <:action :let={issue}>
        <.flex>
          <.button
            variant="minimal"
            link={show_url(issue)}
            icon={:eye}
          >
            View
          </.button>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp show_url(issue) do
    ~p"/robo_sre/issues/#{issue.id}"
  end

  defp handler_label(nil), do: "Not assigned"

  defp handler_label(handler) do
    handler
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
