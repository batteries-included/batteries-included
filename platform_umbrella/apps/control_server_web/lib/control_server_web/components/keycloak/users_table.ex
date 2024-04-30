defmodule ControlServerWeb.Keycloak.UsersTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonUI.Components.DatetimeDisplay

  attr :users, :list, required: true

  def keycloak_users_table(%{} = assigns) do
    ~H"""
    <.table id="keycloak-users-table" rows={@users}>
      <:col :let={user} label="Id"><%= user.id %></:col>
      <:col :let={user} label="Username"><%= user.username %></:col>
      <:col :let={user} label="Enabled"><%= user.enabled %></:col>
      <:col :let={user} label="Email Verified"><%= user.emailVerified %></:col>
      <:col :let={user} label="Created">
        <.relative_display time={DateTime.from_unix!(user.createdTimestamp || 0, :millisecond)} />
      </:col>

      <:action :let={user}>
        <.a
          variant="styled"
          phx-click="reset_password"
          data-confirm="Are you sure?"
          phx-value-user-id={user.id}
        >
          Reset Password
        </.a>
      </:action>
      <:action :let={user}>
        <.a
          variant="styled"
          phx-click="make_realm_admin"
          data-confirm="Are you sure?"
          phx-value-user-id={user.id}
        >
          Make Realm Admin
        </.a>
      </:action>
    </.table>
    """
  end
end
