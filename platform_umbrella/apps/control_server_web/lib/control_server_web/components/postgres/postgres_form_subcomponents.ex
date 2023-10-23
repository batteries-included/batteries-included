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
        <PC.table>
          <PC.tr>
            <PC.th>Name</PC.th>
            <PC.th>Roles</PC.th>
            <PC.th class="w-10"></PC.th>
          </PC.tr>
          <%= for {user, i} <- Enum.with_index(@users) do %>
            <PC.tr>
              <PC.td>
                <%= user.username %>
              </PC.td>
              <PC.td>
                <%= user.roles |> Enum.join(",") |> truncate(length: 25) %>
              </PC.td>
              <PC.td>
                <PC.icon_button
                  type="button"
                  phx-click="del:user"
                  phx-value-idx={i}
                  tooltip="Remove"
                  size="xs"
                  phx-target={@phx_target}
                >
                  <Heroicons.x_mark solid />
                </PC.icon_button>
              </PC.td>
            </PC.tr>
          <% end %>
        </PC.table>
      </div>
    </.panel>
    """
  end

  attr(:phx_target, :any)
  attr(:credential_copies, :list, default: [])

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

      <div :if={@credential_copies != []} class="px-3 pb-6 -mt-3">
        <PC.table>
          <PC.tr>
            <PC.th>Username</PC.th>
            <PC.th>Namespace</PC.th>
            <PC.th>Format</PC.th>
            <PC.th class="w-10"></PC.th>
          </PC.tr>
          <%= for {credential_copy, i} <- Enum.with_index(@credential_copies) do %>
            <PC.tr>
              <PC.td>
                <%= credential_copy.username %>
              </PC.td>
              <PC.td><%= credential_copy.namespace %></PC.td>
              <PC.td><%= credential_copy.format %></PC.td>
              <PC.td>
                <PC.icon_button
                  type="button"
                  phx-click="del:credential_copy"
                  phx-value-idx={i}
                  tooltip="Remove"
                  size="xs"
                  phx-target={@phx_target}
                >
                  <Heroicons.x_mark solid />
                </PC.icon_button>
              </PC.td>
            </PC.tr>
          <% end %>
        </PC.table>
      </div>
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
