defmodule HomeBaseWeb.Live.Admin.TeamsIndex do
  @moduledoc false

  use HomeBaseWeb, :live_view

  import HomeBaseWeb.Admin.TeamsTable

  alias HomeBase.Teams

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Teams")}
  end

  def handle_params(_params, _session, socket) do
    {:noreply, assign(socket, :teams, Teams.list_teams())}
  end

  def render(assigns) do
    ~H"""
    <.flex column>
      <.panel title="All Teams">
        <.teams_table rows={@teams} />
      </.panel>
    </.flex>
    """
  end
end
