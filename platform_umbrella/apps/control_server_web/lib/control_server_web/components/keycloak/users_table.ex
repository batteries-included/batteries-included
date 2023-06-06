defmodule ControlServerWeb.Keycloak.UsersTable do
  use ControlServerWeb, :html

  attr :users, :list, required: true

  def keycloak_users_table(%{} = assigns) do
    ~H"""
    <.table id="keycloak-users-table" rows={@users}>
      <:col :let={user} label="Username"><%= user["username"] %></:col>
      <:col :let={user} label="Enabled"><%= user["enabled"] %></:col>
      <:col :let={user} label="Email Verified"><%= user["emailVerified"] %></:col>
      <:col :let={user} label="Created">
        <%= Timex.from_unix(user["createdTimestamp"], :millisecond) %>
      </:col>
    </.table>
    """
  end
end
