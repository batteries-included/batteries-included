defmodule ControlServerWeb.PostgresFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  attr(:phx_target, :any)
  attr(:users, :list, default: [])

  def users_table(assigns) do
    ~H"""
    <.panel no_body_padding>
      <:title>
        Users
      </:title>

      <:top_right>
        <.new_button label="New user" phx-click="toggle_user_modal" phx-target={@phx_target} />
      </:top_right>

      <div :if={@users == []} class="p-6 text-sm text-gray-500 dark:text-gray-400">
        No users added
      </div>

      <div :if={@users != []} class="px-3 pb-6 -mt-3">
        <.table rows={@users}>
          <:col :let={user} label="Name"><%= user.username %></:col>
          <:col :let={user} label="Roles">
            <%= user.roles |> Enum.join(", ") |> truncate(length: 35) %>
          </:col>
          <:action :let={user}>
            <PC.icon_button
              type="button"
              phx-click="del:user"
              phx-value-username={user.username}
              tooltip="Remove"
              size="xs"
              phx-target={@phx_target}
            >
              <Heroicons.x_mark solid />
            </PC.icon_button>
          </:action>
        </.table>
      </div>
    </.panel>
    """
  end

  attr(:phx_target, :any)
  attr(:credential_copies, :list, default: [])

  @spec credential_copies_table(map()) :: Phoenix.LiveView.Rendered.t()
  def credential_copies_table(assigns) do
    ~H"""
    <.panel no_body_padding>
      <:title>
        Credential Secret Copies
      </:title>
      <:top_right>
        <.new_button
          label="New copy"
          phx-click="toggle_credential_copy_modal"
          phx-target={@phx_target}
        />
      </:top_right>

      <div :if={@credential_copies == []} class="p-6 text-sm text-gray-500 dark:text-gray-400">
        No copies added
      </div>

      <.table :if={@credential_copies != []} rows={@credential_copies}>
        <:col :let={cc} label="Name"><%= cc.username %></:col>
        <:action :let={cc}>
          <PC.icon_button
            type="button"
            phx-click="del:credential_copy"
            phx-value-username={cc.username}
            phx-value-namespace={cc.namespace}
            tooltip="Remove"
            size="xs"
            phx-target={@phx_target}
          >
            <Heroicons.x_mark solid />
          </PC.icon_button>
        </:action>
      </.table>
    </.panel>
    """
  end

  attr(:field, :map)
  attr(:label, :string)
  attr(:help_text, :string)

  def role_option(assigns) do
    ~H"""
    <div class="flex justify-between py-2">
      <div class="flex flex-col gap-2">
        <PC.h5>
          <%= @label %>
        </PC.h5>
        <div class="text-sm text-gray-500">
          <%= @help_text %>
        </div>
      </div>

      <div>
        <.switch name={@field.name <> "[]"} value="login" />
      </div>
    </div>
    """
  end
end
