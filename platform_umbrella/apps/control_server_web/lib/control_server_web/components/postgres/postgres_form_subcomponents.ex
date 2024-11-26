defmodule ControlServerWeb.PostgresFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Util.Memory
  alias Ecto.Changeset
  alias KubeServices.SystemState.SummaryStorage

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
          icon={:plus}
          phx-click="toggle_user_modal"
          phx-target={@phx_target}
          id="new_user_table-new_user"
        >
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

  attr :phx_target, :any
  attr :user_form, :map, default: nil
  attr :possible_namespaces, :list, default: []

  def user_form_modal(assigns) do
    assigns =
      assigns
      |> assign(:roles, @default_roles)
      |> assign(
        :action_text,
        if(
          assigns[:user_form] && Changeset.get_field(assigns.user_form.source, :position),
          do: "Update User",
          else: "Add User"
        )
      )

    ~H"""
    <.form
      for={@user_form}
      id="user-form"
      phx-change="validate:user"
      phx-submit="upsert:user"
      phx-target={@phx_target}
    >
      <.modal
        :if={@user_form}
        show
        id="user-form-modal"
        size="lg"
        on_cancel={JS.push("close_modal", target: @phx_target)}
      >
        <:title><%= @action_text %></:title>

        <.fieldset>
          <.input field={@user_form[:position]} type="hidden" />

          <.field>
            <:label>User Name</:label>
            <.input field={@user_form[:username]} autocomplete="off" />
          </.field>

          <.field>
            <:label>Namespaces</:label>
            <.input
              type="multiselect"
              field={@user_form[:credential_namespaces]}
              options={Enum.map(@possible_namespaces, &%{name: &1, value: &1})}
            />
          </.field>

          <.fieldset responsive>
            <.field
              :for={role <- @roles}
              variant="beside"
              class="bg-gray-lightest dark:bg-gray-darkest-tint rounded-lg p-3 cursor-pointer"
            >
              <:label class="text-xl font-semibold"><%= role.label %></:label>
              <:note><%= role.help_text %></:note>
              <.input
                type="switch"
                name={@user_form[:roles].name <> "[]"}
                value={role.value}
                checked={Enum.member?(@user_form[:roles].value, role.value)}
              />
            </.field>
          </.fieldset>
        </.fieldset>

        <:actions cancel="Cancel">
          <.button variant="primary" type="submit"><%= @action_text %></.button>
        </:actions>
      </.modal>
    </.form>
    """
  end

  attr :phx_target, :any
  attr :class, :any, default: nil
  attr :action, :atom, default: nil
  attr :with_divider, :boolean, default: true
  attr :form, Phoenix.HTML.Form, required: true
  attr :ticks, :list, required: true

  def size_form(assigns) do
    ~H"""
    <.fieldset responsive class={@class}>
      <.field>
        <:label>Name</:label>
        <.input field={@form[:name]} autofocus={@action == :new} disabled={@action != :new} />
      </.field>

      <.field id="postgres_virtual_size">
        <:label>Size</:label>
        <.input
          type="select"
          field={@form[:virtual_size]}
          options={Cluster.preset_options_for_select()}
        />
      </.field>

      <.data_list
        :if={@form[:virtual_size].value != "custom"}
        variant="horizontal-bolded"
        class="lg:col-span-2"
        data={[
          {"Storage size:", Memory.humanize(@form[:storage_size].value)},
          {"Memory limits:", Memory.humanize(@form[:memory_limits].value)},
          {"CPU limits:", @form[:cpu_limits].value}
        ]}
      />

      <%= if @form[:virtual_size].value == "custom" do %>
        <.h3 class="lg:col-span-2">Storage</.h3>

        <.fieldset responsive>
          <.field>
            <:label>Storage Class</:label>
            <.input
              type="select"
              field={@form[:storage_class]}
              options={Enum.map(SummaryStorage.storage_classes(), &get_in(&1, ["metadata", "name"]))}
            />
          </.field>

          <.field>
            <:label>Storage Size · <%= Memory.humanize(@form[:storage_size].value) %></:label>
            <:note>You can't reduce this once it has been created.</:note>
            <.input type="number" field={@form[:storage_size]} debounce={false} />
          </.field>
        </.fieldset>

        <.field>
          <.input
            type="range"
            field={@form[:virtual_storage_size_range_value]}
            show_value={false}
            min={@ticks |> Memory.min_range_value()}
            max={@ticks |> Memory.max_range_value()}
            ticks={@ticks}
            tick_target={@phx_target}
            tick_click="change_storage_size_range"
            phx-change="change_storage_size_range"
            lower_boundary={@form.data.storage_size |> Memory.bytes_to_range_value(@ticks)}
            class="px-5 self-center"
          />
        </.field>

        <.h3 class="lg:col-span-2">Running Limits</.h3>

        <.fieldset responsive>
          <.field>
            <:label>CPU Requested</:label>
            <.input
              type="select"
              field={@form[:cpu_requested]}
              options={Cluster.cpu_select_options()}
            />
          </.field>

          <.field>
            <:label>CPU Limits</:label>
            <.input type="select" field={@form[:cpu_limits]} options={Cluster.cpu_select_options()} />
          </.field>
        </.fieldset>

        <.fieldset responsive>
          <.field>
            <:label>Memory Requested</:label>
            <.input
              type="select"
              field={@form[:memory_requested]}
              options={Cluster.memory_options() |> Memory.bytes_as_select_options()}
            />
          </.field>

          <.field>
            <:label>Memory Limits</:label>
            <.input
              type="select"
              field={@form[:memory_limits]}
              options={Cluster.memory_options() |> Memory.bytes_as_select_options()}
            />
          </.field>
        </.fieldset>
      <% end %>
    </.fieldset>
    """
  end
end
