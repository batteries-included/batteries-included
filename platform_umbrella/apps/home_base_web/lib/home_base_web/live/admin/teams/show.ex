defmodule HomeBaseWeb.Live.Admin.TeamsShow do
  @moduledoc false

  use HomeBaseWeb, :live_view

  import HomeBaseWeb.Admin.InstallationsTable
  import HomeBaseWeb.Admin.UsersTable

  alias HomeBase.Teams

  def mount(%{"id" => id}, _session, socket) do
    team = Teams.get_team!(id)

    {:ok, assign(socket, :team, team)}
  end

  def render(assigns) do
    ~H"""
    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="Team">
        <.data_list>
          <:item title="ID"><%= @team.id %></:item>
          <:item title="Name"><%= @team.name %></:item>
        </.data_list>
      </.panel>
      <.panel title="Users">
        <.users_table rows={@team.users} />
      </.panel>

      <.panel title="Installations" class="lg:col-span-2">
        <.installations_table rows={@team.installations} />
      </.panel>
    </.grid>
    """
  end
end
