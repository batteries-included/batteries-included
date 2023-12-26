defmodule ControlServerWeb.PostgresFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonUI.MutliSelect

  alias Ecto.Changeset

  @default_roles [
    %{
      label: "Superuser",
      value: "superuser",
      help_text: "A special user account used for system administration"
    },
    %{
      label: "Createdb",
      value: "createdb",
      help_text: "Allowed to create new databases"
    },
    %{
      label: "Createrole",
      value: "createrole",
      help_text: "User can create new roles"
    },
    %{
      label: "Inherit",
      value: "inherit",
      help_text: "Alows grants with inheritance"
    },
    %{
      label: "Login",
      value: "login",
      help_text: "A user is allowed to log in"
    },
    %{
      label: "Replication",
      value: "replication",
      help_text: "A user is a replication user"
    },
    %{
      label: "Bypassrls",
      value: "bypassrls",
      help_text: "Determine whether a user bypasses row-level security (RLS) policy"
    }
  ]

  attr :phx_target, :any
  attr :users, :list, default: []

  def users_table(assigns) do
    ~H"""
    <.panel title="Users">
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
    </.panel>
    """
  end

  attr :field, :map, required: true
  attr :label, :string
  attr :help_text, :string
  attr :rest, :global, include: ~w(checked value)

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

  attr :phx_target, :any
  attr :user_form, :map, default: nil
  attr :possible_namespaces, :list, default: []

  def user_form_modal(assigns) do
    assigns =
      assigns
      |> assign(:roles, @default_roles)
      |> assign(
        :action_text,
        if(assigns[:user_form] && assigns.user_form.data.position,
          do: "Update user",
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
        <.flex column>
          <PC.field field={@user_form[:position]} type="hidden" />
          <PC.field field={@user_form[:username]} label="User Name" />

          <.muliselect_input
            form={@user_form}
            field={@user_form[:credential_namespaces]}
            options={to_options(@possible_namespaces, @user_form)}
            label="Namespaces"
            width_class="w-full"
            phx_target={@phx_target}
            change_event="change:credential_namespaces"
          />
          <PC.h3>Roles</PC.h3>
          <.grid columns={%{sm: 1, xl: 2}} gaps="2">
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
        </.flex>
      </.form>
    </PC.modal>
    """
  end

  defp to_options(namespaces, form) do
    selected = Changeset.get_field(form.source, :credential_namespaces)

    Enum.map(namespaces, fn ns ->
      %{label: ns, value: ns, selected: Enum.member?(selected, ns)}
    end)
  end
end
