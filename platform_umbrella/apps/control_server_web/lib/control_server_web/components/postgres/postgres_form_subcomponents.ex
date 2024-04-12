defmodule ControlServerWeb.PostgresFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Util.Memory
  alias CommonCore.Util.MemorySliderConverter
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

  @doc """
  This macro creates all the LiveView events needed for the subform components.
  """
  defmacro __using__(opts \\ []) do
    # The main Postgres form uses the key "cluster", whereas the nested forms
    # in the New Project pages use the key "postgres" to differentiate between
    # the Redis clusters. This allows the same events to be used with different
    # form keys.
    form_key = Keyword.get(opts, :form_key, "cluster")

    quote do
      alias CommonCore.Postgres.Cluster, as: PGCluster
      alias ControlServerWeb.PostgresFormSubcomponents

      def handle_event("set_storage_size_shortcut", %{"bytes" => bytes}, socket) do
        handle_event("change_storage_size", %{unquote(form_key) => %{"storage_size" => bytes}}, socket)
      end

      # This only happens when the user is manually editing the storage size.
      # In this case, we need to update the range slider and helper text "x GB"
      def handle_event("change_storage_size", %{unquote(form_key) => %{"storage_size" => storage_size}}, socket) do
        changeset =
          socket.assigns.form
          |> get_source()
          |> PGCluster.put_storage_size_bytes(storage_size)

        form = socket.assigns.form |> put_source(changeset) |> to_form()

        {:noreply, assign(socket, :form, form)}
      end

      def handle_event(
            "on_change_storage_size_range",
            %{unquote(form_key) => %{"virtual_storage_size_range_value" => virtual_storage_size_range_value}},
            socket
          ) do
        changeset =
          socket.assigns.form
          |> get_source()
          |> PGCluster.put_storage_size_value(virtual_storage_size_range_value)

        form = socket.assigns.form |> put_source(changeset) |> to_form()

        {:noreply, assign(socket, form: form)}
      end

      defp get_source(%{source: source}) do
        if unquote(form_key) != "cluster", do: source[unquote(form_key)], else: source
      end

      defp put_source(%{source: source}, value) do
        if unquote(form_key) != "cluster", do: Map.put(source, unquote(form_key), value), else: value
      end
    end
  end

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

  attr :phx_target, :any
  attr :class, :any, default: nil
  attr :with_divider, :boolean, default: true
  attr :form, Phoenix.HTML.Form, required: true

  def size_form(assigns) do
    ~H"""
    <div class={["contents", @class]}>
      <.grid columns={[sm: 1, xl: 2]}>
        <.input field={@form[:name]} label="Name" autofocus />

        <.input
          field={@form[:virtual_size]}
          type="select"
          label="Size"
          options={Cluster.preset_options_for_select()}
        />
      </.grid>

      <.data_horizontal_bolded
        :if={@form[:virtual_size].value != "custom"}
        class="mt-3 mb-5"
        data={[
          {"Storage size:", @form[:storage_size].value |> Memory.format_bytes(true) || "0GB"},
          {"Memory limits:", @form[:memory_limits].value |> Memory.format_bytes(true)},
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

          <.flex>
            <.click_flip
              class="grow flex-1 justify-start xl:justify-end items-center"
              cursor_class="cursor-text"
              tooltip="Click to Edit"
              id="storage-size-input"
            >
              <span>
                <div class="text-sm">Storage Size</div>
                <%= Memory.format_bytes(@form[:storage_size].value, true) || "0GB" %>
              </span>
              <:hidden>
                <.input field={@form[:storage_size]} type="number" phx-change="change_storage_size" />
              </:hidden>
            </.click_flip>
          </.flex>

          <div class="pt-3 pb-1 mb-[22px] lg:col-span-2">
            <.flex class="justify-between w-full">
              <%= for memory_size <- MemorySliderConverter.control_points() do %>
                <span
                  phx-click="set_storage_size_shortcut"
                  phx-value-bytes={memory_size}
                  phx-target={@phx_target}
                  class="cursor-pointer hover:underline text-sm font-medium text-gray-darkest dark:text-white w-[45px] text-center"
                >
                  <%= Memory.format_bytes(memory_size) %>
                </span>
              <% end %>
            </.flex>

            <.input
              field={@form[:virtual_storage_size_range_value]}
              type="range"
              min="1"
              max="120"
              step="1"
              show_value={false}
              phx-change="on_change_storage_size_range"
            />
          </div>
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
              options={Cluster.memory_limits_options() |> Memory.bytes_as_select_options()}
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
