defmodule HomeBaseWeb.Admin.UsersTable do
  @moduledoc false

  use HomeBaseWeb, :html

  attr :rows, :list, default: []

  def users_table(assigns) do
    ~H"""
    <.table id="users-table" rows={@rows} row_click={&JS.navigate(~p"/admin/users/#{&1}")}>
      <:col :let={user} label="ID"><%= user.id %></:col>
      <:col :let={user} label="Email"><%= user.email %></:col>
      <:col :let={user} label="Confirmed At">
        <%= user.confirmed_at %>
      </:col>

      <:action :let={user}>
        <.button
          variant="minimal"
          link={~p"/admin/users/#{user}"}
          icon={:eye}
          id={"show_user_" <> user.id}
        />

        <.tooltip target_id={"show_user_" <> user.id}>
          Show User
        </.tooltip>
      </:action>
    </.table>
    """
  end
end
