defmodule ControlServerWeb.PostgresFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  attr(:phx_target, :any)
  attr(:users, :list, default: [])

  def users_table(assigns) do
    ~H"""
    <.panel no_body_padding title="Users">
      <:menu>
        <.button
          variant="transparent"
          icon={:plus}
          phx-click="toggle_user_modal"
          type="button"
          phx-target={@phx_target}
        >
          New user
        </.button>
      </:menu>

      <div :if={@users == []} class="p-6 text-sm text-gray-500 dark:text-gray-400">
        No users added
      </div>

      <div :if={@users != []} class="px-3 pb-6 -mt-3">
        <.table rows={@users} id="users_table">
          <:col :let={user} label="Name"><%= user.username %></:col>
          <:col :let={user} label="Roles">
            <%= user.roles |> Enum.join(", ") |> truncate(length: 35) %>
          </:col>
          <:action :let={user}>
            <.flex>
              <.action_icon
                icon={:pencil}
                id={"edit_user_" <> String.replace(user.username, " ", "")}
                phx-click="edit:user"
                phx-value-username={user.username}
                tooltip="Edit"
                link_type="button"
                type="button"
                phx-target={@phx_target}
              />
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
            </.flex>
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
    <.panel no_body_padding title="Credential Secret Copies">
      <:menu>
        <.button
          variant="transparent"
          icon={:plus}
          phx-click="toggle_credential_copy_modal"
          phx-target={@phx_target}
          type="button"
        >
          New copy
        </.button>
      </:menu>

      <div :if={@credential_copies == []} class="p-6 text-sm text-gray-500 dark:text-gray-400">
        No copies added
      </div>

      <div :if={@credential_copies != []} class="px-3 pb-6 -mt-3">
        <.table rows={@credential_copies} id="credential_copies_table">
          <:col :let={cc} label="Name"><%= cc.username %></:col>
          <:col :let={cc} label="Namespace"><%= cc.namespace %></:col>
          <:col :let={cc} label="Format"><%= cc.format %></:col>
          <:action :let={cc}>
            <.action_icon
              icon={:pencil}
              id={"edit_credential_copy_" <> String.replace("#{cc.namespace}_#{cc.username}", " ", "")}
              phx-click="edit:credential_copy"
              phx-value-username={cc.username}
              phx-value-namespace={cc.namespace}
              tooltip="Edit"
              link_type="button"
              type="button"
              phx-target={@phx_target}
            />
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

  attr(:field, :map, required: true)
  attr(:label, :string)
  attr(:help_text, :string)
  attr(:rest, :global, include: ~w(checked value))

  def role_option(assigns) do
    ~H"""
    <div class="flex justify-between py-2">
      <div class="flex flex-col gap-2">
        <.h5>
          <%= @label %>
        </.h5>
        <div class="text-sm text-gray-500">
          <%= @help_text %>
        </div>
      </div>

      <div>
        <.switch name={@field.name <> "[]"} {@rest} />
      </div>
    </div>
    """
  end

  attr(:phx_target, :any)
  attr(:user_form, :map, default: nil)

  def user_form_modal(assigns) do
    assigns =
      assigns
      |> assign(:roles, [
        %{
          label: "Superuser",
          value: "superuser",
          help_text: "A special user account used for system administration"
        },
        %{
          label: "Createdb",
          value: "createdb",
          help_text: "This role being defined will be allowed to create new databases"
        },
        %{
          label: "Createrole",
          value: "createrole",
          help_text: "A special user account used for system administration"
        },
        %{
          label: "Inherit",
          value: "inherit",
          help_text: "A special user account used for system administration"
        },
        %{
          label: "Login",
          value: "login",
          help_text: "A special user account used for system administration"
        },
        %{
          label: "Replication",
          value: "replication",
          help_text: "A special user account used for system administration"
        },
        %{
          label: "Bypassrls",
          value: "bypassrls",
          help_text: "A special user account used for system administration"
        }
      ])
      |> assign(
        :action_text,
        if(assigns[:user_form] && assigns.user_form.data.position,
          do: "Edit user",
          else: "Add user"
        )
      )

    ~H"""
    <PC.modal
      :if={@user_form}
      id="user_modal"
      max_width="lg"
      title={@action_text}
      close_modal_target={@phx_target}
    >
      <.form for={@user_form} phx-submit="upsert:user" phx-target={@phx_target}>
        <PC.field field={@user_form[:position]} type="hidden" />
        <PC.field field={@user_form[:username]} label="User Name" />
        <PC.h3 class="!mt-8 !mb-6 !text-gray-500">Roles</PC.h3>
        <.grid columns={%{sm: 1, xl: 2}} class="mb-8">
          <.role_option
            :for={role <- @roles}
            field={@user_form[:roles]}
            value={role.value}
            label={role.label}
            help_text={role.help_text}
            checked={Enum.member?(@user_form[:roles].value, role.value)}
          />
        </.grid>

        <.flex class="justify-end">
          <.button phx-target={@phx_target} phx-click="close_modal">
            Cancel
          </.button>
          <PC.button><%= @action_text %></PC.button>
        </.flex>
      </.form>
    </PC.modal>
    """
  end

  attr(:phx_target, :any)
  attr(:possible_owners, :list, default: [])
  attr(:possible_namespaces, :list, default: [])
  attr(:possible_formats, :list, default: [])
  attr(:credential_copy_form, :map, default: nil)

  def credential_copy_form_modal(assigns) do
    assigns =
      assign(
        assigns,
        :action_text,
        if(assigns[:credential_copy_form] && assigns.credential_copy_form.data.position,
          do: "Edit copy",
          else: "Add copy"
        )
      )

    ~H"""
    <PC.modal
      :if={@credential_copy_form}
      id="credential_copy_modal"
      max_width="lg"
      title={@action_text}
      close_modal_target={@phx_target}
    >
      <.form for={@credential_copy_form} phx-submit="upsert:credential_copy" phx-target={@phx_target}>
        <PC.field field={@credential_copy_form[:position]} type="hidden" />
        <PC.field field={@credential_copy_form[:username]} type="select" options={@possible_owners} />
        <PC.field
          field={@credential_copy_form[:namespace]}
          type="select"
          options={@possible_namespaces}
        />
        <PC.field field={@credential_copy_form[:format]} type="select" options={@possible_formats} />

        <.flex class="justify-end">
          <.button phx-target={@phx_target} phx-click="close_modal">
            Cancel
          </.button>
          <PC.button><%= @action_text %></PC.button>
        </.flex>
      </.form>
    </PC.modal>
    """
  end
end
