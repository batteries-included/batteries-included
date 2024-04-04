defmodule ControlServerWeb.PostgresFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

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
        <.button icon={:plus} phx-click="toggle_user_modal" phx-target={@phx_target}>
          New User
        </.button>
      </:menu>

      <div :if={@users == []} class="p-6 text-sm text-gray-dark dark:text-gray">
        No users added
      </div>

      <.table rows={@users} id="users_table">
        <:col :let={user} label="Name"><%= user.username %></:col>
        <:col :let={user} label="Roles">
          <%= user.roles |> Enum.join(", ") |> truncate(length: 35) %>
        </:col>
        <:action :let={user}>
          <.flex>
            <.button
              variant="minimal"
              icon={:pencil}
              id={"edit_user_" <> String.replace(user.username, " ", "")}
              phx-click="edit:user"
              phx-value-username={user.username}
              phx-target={@phx_target}
            />

            <.tooltip target_id={"edit_user_" <> String.replace(user.username, " ", "")}>
              Edit
            </.tooltip>

            <.button
              variant="minimal"
              icon={:x_mark}
              id={"delete_user_" <> String.replace(user.username, " ", "")}
              phx-click="del:user"
              phx-value-username={user.username}
              phx-target={@phx_target}
            />

            <.tooltip target_id={"delete_user_" <> String.replace(user.username, " ", "")}>
              Remove
            </.tooltip>
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
        <div class="text-sm text-gray-dark">
          <%= @help_text %>
        </div>
      </div>

      <div>
        <.input type="switch" name={@field.name <> "[]"} {@rest} />
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
    <.form for={@user_form} id="user-form" phx-submit="upsert:user" phx-target={@phx_target}>
      <.modal
        :if={@user_form}
        show
        id="user-form-modal"
        size="lg"
        on_cancel={JS.push("close_modal", target: @phx_target)}
      >
        <:title><%= @action_text %></:title>

        <.input field={@user_form[:position]} type="hidden" />
        <.input field={@user_form[:username]} label="User Name" />

        <.muliselect_input
          form={@user_form}
          field={@user_form[:credential_namespaces]}
          options={to_options(@possible_namespaces, @user_form)}
          label="Namespaces"
          width_class="w-full"
          phx_target={@phx_target}
          change_event="change:credential_namespaces"
        />

        <.h3 class="my-4">Roles</.h3>
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

        <:actions cancel="Cancel">
          <.button variant="primary" type="submit"><%= @action_text %></.button>
        </:actions>
      </.modal>
    </.form>
    """
  end

  defp to_options(namespaces, form) do
    selected = Changeset.get_field(form.source, :credential_namespaces)

    Enum.map(namespaces, fn ns ->
      %{label: ns, value: ns, selected: Enum.member?(selected, ns)}
    end)
  end
end
