defmodule HomeBaseWeb.Live.Admin.UsersShow do
  @moduledoc false

  use HomeBaseWeb, :live_view

  import HomeBaseWeb.Admin.TeamsTable

  alias HomeBase.Accounts

  def mount(%{"id" => id}, _session, socket) do
    user = Accounts.get_user!(id)

    {:ok, assign(socket, :user, user)}
  end

  def render(assigns) do
    ~H"""
    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="User">
        <.data_list>
          <:item title="ID"><%= @user.id %></:item>
          <:item title="email"><%= @user.email %></:item>
          <:item title="Confirmed at"><%= @user.confirmed_at %></:item>
        </.data_list>
      </.panel>
      <.panel title="Teams">
        <.teams_table rows={@user.teams} />
      </.panel>
      <.panel title="Installations" class="lg:col-span-2"></.panel>
    </.grid>
    """
  end
end
