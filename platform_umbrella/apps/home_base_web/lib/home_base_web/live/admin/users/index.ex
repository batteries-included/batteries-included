defmodule HomeBaseWeb.Live.Admin.UsersIndex do
  @moduledoc false
  use HomeBaseWeb, :live_view

  import HomeBaseWeb.Admin.UsersTable

  alias HomeBase.Accounts

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Users")}
  end

  def handle_params(_params, _session, socket) do
    {:noreply, assign(socket, :users, Accounts.list_users())}
  end

  def render(assigns) do
    ~H"""
    <.flex column>
      <.panel title="All Users">
        <.users_table rows={@users} />
      </.panel>
    </.flex>
    """
  end
end
