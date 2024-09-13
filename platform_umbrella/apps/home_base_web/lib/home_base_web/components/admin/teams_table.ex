defmodule HomeBaseWeb.Admin.TeamsTable do
  @moduledoc false

  use HomeBaseWeb, :html

  attr :rows, :list, default: []

  def teams_table(assigns) do
    ~H"""
    <.table id="teams-table" rows={@rows} row_click={&JS.navigate(~p"/admin/teams/#{&1}")}>
      <:col :let={team} label="ID"><%= team.id %></:col>
      <:col :let={team} label="name"><%= team.name %></:col>

      <:action :let={team}>
        <.button
          variant="minimal"
          link={~p"/admin/teams/#{team}"}
          icon={:eye}
          id={"show_team_" <> team.id}
        />

        <.tooltip target_id={"show_team_" <> team.id}>
          Show Team
        </.tooltip>
      </:action>
    </.table>
    """
  end
end
