defmodule ControlServerWeb.PostgresFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  attr :phx_target, :any
  attr :users, :list, default: []

  def users_table(assigns) do
    ~H"""
    <.panel no_body_padding title="Users">
      <:top_right>
        <.button
          variant="transparent"
          icon={:plus}
          phx-click="toggle_user_modal"
          type="button"
          phx-target={@phx_target}
        >
          New user
        </.button>
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
            <.action_icon
              to="/"
              icon={:x_mark}
              id={"delete_user_" <> String.replace(user.username, " ", "")}
              phx-click="del:user"
              phx-value-username={user.username}
              tooltip="Remove"
              link_type="button"
              type="button"
              phx-target={@phx_target}
            />
          </:action>
        </.table>
      </div>
    </.panel>
    """
  end

  attr :phx_target, :any
  attr :credential_copies, :list, default: []

  @spec credential_copies_table(map()) :: Phoenix.LiveView.Rendered.t()
  def credential_copies_table(assigns) do
    ~H"""
    <.panel no_body_padding title="Credential Secret Copies">
      <:top_right>
        <.button
          variant="transparent"
          icon={:plus}
          phx-click="toggle_credential_copy_modal"
          phx-target={@phx_target}
          type="button"
        >
          New copy
        </.button>
      </:top_right>

      <div :if={@credential_copies == []} class="p-6 text-sm text-gray-500 dark:text-gray-400">
        No copies added
      </div>

      <div :if={@credential_copies != []} class="px-3 pb-6 -mt-3">
        <.table rows={@credential_copies}>
          <:col :let={cc} label="Name"><%= cc.username %></:col>
          <:action :let={cc}>
            <.action_icon
              to="/"
              icon={:x_mark}
              id={"delete_credential_copy_" <> String.replace("#{cc.namespace}_#{cc.username}", " ", "")}
              phx-click="del:credential_copy"
              phx-value-username={cc.username}
              phx-value-namespace={cc.namespace}
              tooltip="Remove"
              link_type="button"
              type="button"
              phx-target={@phx_target}
            />
          </:action>
        </.table>
      </div>
    </.panel>
    """
  end

  attr :field, :map, required: true
  attr :value, :string, required: true
  attr :label, :string
  attr :help_text, :string

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
        <.switch name={@field.name <> "[]"} value={@value} />
      </div>
    </div>
    """
  end
end
