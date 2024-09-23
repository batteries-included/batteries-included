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
    <.modal
      :if={@user_form}
      show
      id="user-form-modal"
      size="lg"
      on_cancel={JS.push("close_modal", target: @phx_target)}
    >
      <:title><%= @action_text %></:title>

      <.simple_form
        for={@user_form}
        id="user-form"
        phx-change="validate:user"
        phx-submit="upsert:user"
        phx-target={@phx_target}
      >
        <.input field={@user_form[:position]} type="hidden" />
        <.input field={@user_form[:username]} label="User Name" autocomplete="off" />

        <.input
          field={@user_form[:credential_namespaces]}
          type="multiselect"
          label="Namespaces"
          options={Enum.map(@possible_namespaces, &%{name: &1, value: &1})}
        />

        <.grid columns={%{sm: 1, xl: 2}} gaps="8">
          <.role_option
            :for={role <- @roles}
            field={@user_form[:roles]}
            value={role.value}
            label={role.label}
            help_text={role.help_text}
            checked={Enum.member?(@user_form[:roles].value, role.value)}
          />
        </.grid>

        <:actions>
          <.button variant="primary" type="submit"><%= @action_text %></.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  attr :field, :map, required: true
  attr :label, :string
  attr :help_text, :string
  attr :rest, :global, include: ~w(checked value)

  def role_option(assigns) do
    ~H"""
    <div class="flex items-start justify-between gap-x-12">
      <div>
        <h3 class="text-xl font-semibold mb-2"><%= @label %></h3>
        <p class="text-sm"><%= @help_text %></p>
      </div>

      <.input type="switch" name={@field.name <> "[]"} {@rest} />
    </div>
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
    <div class={["contents", @class]}>
      <.grid columns={[sm: 1, xl: 2]}>
        <.input
          field={@form[:name]}
          label="Name"
          autofocus={@action == :new}
          disabled={@action != :new}
        />

        <.input
          field={@form[:virtual_size]}
          type="select"
          label="Size"
          options={Cluster.preset_options_for_select()}
        />
      </.grid>

      <.data_list
        :if={@form[:virtual_size].value != "custom"}
        variant="horizontal-bolded"
        class="mt-3 mb-5"
        data={[
          {"Storage size:", Memory.humanize(@form[:storage_size].value)},
          {"Memory limits:", Memory.humanize(@form[:memory_limits].value)},
          {"CPU limits:", @form[:cpu_limits].value}
        ]}
      />

      <div :if={@form[:virtual_size].value == "custom"} class="mt-2 mb-5">
        <.h3>Storage</.h3>

        <.grid>
          <.input
            field={@form[:storage_class]}
            type="select"
            label="Storage Class"
            options={Enum.map(SummaryStorage.storage_classes(), &get_in(&1, ["metadata", "name"]))}
          />

          <.input
            field={@form[:storage_size]}
            type="number"
            label="Storage Size"
            label_note={Memory.humanize(@form[:storage_size].value)}
            note="You can't reduce this once it has been created."
            debounce={false}
          />

          <.input
            field={@form[:virtual_storage_size_range_value]}
            type="range"
            show_value={false}
            min={@ticks |> Memory.min_range_value()}
            max={@ticks |> Memory.max_range_value()}
            ticks={@ticks}
            tick_target={@phx_target}
            tick_click="change_storage_size_range"
            phx-change="change_storage_size_range"
            class="px-5 self-center lg:col-span-2"
            lower_boundary={@form.data.storage_size |> Memory.bytes_to_range_value(@ticks)}
          />
        </.grid>

        <.h3>Running Limits</.h3>

        <.grid>
          <div>
            <.input
              field={@form[:cpu_requested]}
              type="select"
              label="CPU Requested"
              options={Cluster.cpu_select_options()}
            />
          </div>
          <div>
            <.input
              field={@form[:cpu_limits]}
              type="select"
              label="CPU Limits"
              options={Cluster.cpu_select_options()}
            />
          </div>
          <div>
            <.input
              field={@form[:memory_requested]}
              type="select"
              label="Memory Requested"
              options={Cluster.memory_options() |> Memory.bytes_as_select_options()}
            />
          </div>
          <div>
            <.input
              field={@form[:memory_limits]}
              type="select"
              label="Memory Limits"
              options={Cluster.memory_options() |> Memory.bytes_as_select_options()}
            />
          </div>
        </.grid>
      </div>

      <.flex
        :if={@with_divider}
        class="justify-between w-full py-3 border-t border-gray-lighter dark:border-gray-darker"
      />
    </div>
    """
  end
end
