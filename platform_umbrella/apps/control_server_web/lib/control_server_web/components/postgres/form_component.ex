defmodule ControlServerWeb.Live.PostgresFormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.PostgresFormSubcomponents

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGCredentialCopy
  alias CommonCore.Postgres.PGUser
  alias CommonCore.Util.Memory
  alias ControlServer.Postgres
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "cluster:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  @impl Phoenix.LiveComponent
  def update(%{cluster: cluster} = assigns, socket) do
    changeset = Postgres.change_cluster(cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))
     |> assign(:possible_owners, possible_owners(changeset))
     |> assign(:full_name, full_name(cluster))
     |> assign(:possible_storage_classes, possible_storage_classes())
     |> assign(:possible_namespaces, possible_namespaces())
     |> assign(:num_instances, cluster.num_instances)
     |> assign(:pg_user_form, nil)
     |> assign(:pg_credential_copy_form, nil)}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, pg_user_form: nil, pg_credential_copy_form: nil)}
  end

  def handle_event("toggle_user_modal", _, socket) do
    pg_user_form =
      %PGUser{username: "", roles: ["login"]}
      |> PGUser.changeset()
      |> to_form()

    {:noreply, assign(socket, pg_user_form: pg_user_form)}
  end

  def handle_event("toggle_credential_copy_modal", _, socket) do
    pg_credential_copy_form =
      %PGCredentialCopy{username: "", namespace: "", format: "dsn"}
      |> PGCredentialCopy.changeset()
      |> to_form()

    {:noreply, assign(socket, pg_credential_copy_form: pg_credential_copy_form)}
  end

  def handle_event("add:user", %{"pg_user" => pg_user_params}, %{assigns: %{form: %{source: changeset}}} = socket) do
    pg_user_changeset = PGUser.changeset(%PGUser{}, pg_user_params)

    case Ecto.Changeset.apply_action(pg_user_changeset, :validate) do
      {:ok, pg_user} ->
        users = Changeset.get_field(changeset, :users, []) ++ [pg_user]
        final_changeset = Changeset.put_embed(changeset, :users, users)

        {:noreply,
         socket
         |> assign(form: to_form(final_changeset))
         |> assign(pg_user_form: nil)
         |> assign(possible_owners: possible_owners(final_changeset))}

      {:error, changeset} ->
        {:noreply, assign(socket, pg_user_form: to_form(changeset))}
    end
  end

  def handle_event("del:user", %{"idx" => idx}, %{assigns: %{form: %{source: changeset}}} = socket) do
    users = changeset |> Changeset.get_field(:users, []) |> List.delete_at(String.to_integer(idx))

    final_changeset = Changeset.put_embed(changeset, :users, users)

    {:noreply,
     socket
     |> assign(form: to_form(final_changeset))
     |> assign(changeset: final_changeset)
     |> assign(:possible_owners, possible_owners(final_changeset))}
  end

  def handle_event(
        "add:credential_copy",
        %{"pg_credential_copy" => pg_credential_copy_params},
        %{assigns: %{form: %{source: changeset}}} = socket
      ) do
    pg_credential_copy_changeset = PGCredentialCopy.changeset(%PGCredentialCopy{}, pg_credential_copy_params)

    case Ecto.Changeset.apply_action(pg_credential_copy_changeset, :validate) do
      {:ok, pg_credential_copy} ->
        credential_copies = Changeset.get_field(changeset, :credential_copies, []) ++ [pg_credential_copy]

        final_changeset = Changeset.put_embed(changeset, :credential_copies, credential_copies)

        {:noreply,
         socket
         |> assign(form: to_form(final_changeset))
         |> assign(changeset: final_changeset)
         |> assign(pg_credential_copy_form: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, pg_credential_copy_form: to_form(changeset))}
    end
  end

  def handle_event("del:credential_copy", %{"idx" => idx}, %{assigns: %{form: %{source: changeset}}} = socket) do
    credential_copies =
      changeset
      |> Changeset.get_field(:credential_copies, [])
      |> List.delete_at(String.to_integer(idx))

    final_changeset = Changeset.put_embed(changeset, :credential_copies, credential_copies)

    {:noreply,
     socket
     |> assign(form: to_form(final_changeset))
     |> assign(changeset: final_changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"cluster" => cluster_params}, socket) do
    cluster_params = prepare_cluster_params(cluster_params, socket)
    {changeset, data} = Cluster.validate(cluster_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset))
     |> assign(changeset: changeset)
     |> assign(:possible_owners, possible_owners(changeset))
     |> assign(:full_name, full_name(data))
     |> assign(:num_instances, data.num_instances)}
  end

  def handle_event("set_storage_size_shortcut", %{"bytes" => bytes}, socket) do
    virtual_storage_size_range_value =
      CommonCore.Util.MemorySliderConverter.bytes_to_slider_value(String.to_integer(bytes))

    form =
      socket.assigns.form.source
      |> Changeset.put_change(:virtual_storage_size_range_value, virtual_storage_size_range_value)
      |> Changeset.put_change(:storage_size, bytes)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"cluster" => cluster_params}, socket) do
    cluster_params = prepare_cluster_params(cluster_params, socket)
    save_cluster(socket, socket.assigns.action, cluster_params)
  end

  defp save_cluster(socket, :new, cluster_params) do
    case Postgres.create_cluster(cluster_params) do
      {:ok, new_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Postgres Cluster created successfully")
         |> send_info(socket.assigns.save_target, new_cluster)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cluster(socket, :edit, cluster_params) do
    case Postgres.update_cluster(socket.assigns.cluster, cluster_params) do
      {:ok, updated_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Postgres Cluster updated successfully")
         |> send_info(socket.assigns.save_target, updated_cluster)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp send_info(socket, nil, _cluster), do: {:noreply, socket}

  defp send_info(socket, target, cluster) do
    send(target, {socket.assigns.save_info, %{"cluster" => cluster}})
    socket
  end

  defp possible_owners(%Changeset{} = changeset) do
    # get any possible owners from changesets of adding users
    usernames =
      changeset
      |> Changeset.get_field(:users, [])
      |> Enum.map(& &1.username)

    # Finally assume that previous owners are ok
    existing_owners =
      changeset
      |> Changeset.get_field(:databases, [])
      |> Enum.map(& &1.owner)

    usernames
    |> Enum.concat(existing_owners)
    |> Enum.filter(&(&1 != nil))
    |> Enum.uniq()
    |> Enum.sort()
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        id="cluster-form"
        for={@form}
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
        <.page_header
          title="New Postgres Cluster"
          back_button={%{link_type: "live_redirect", to: ~p"/postgres"}}
        >
          <:right_side>
            <PC.button label="Save Cluster" color="dark" phx-disable-with="Saving…" />
          </:right_side>
        </.page_header>
        <.panel class="mb-6">
          <div class="grid grid-cols-2 gap-6">
            <PC.field field={@form[:name]} autofocus />
            <PC.field
              field={@form[:virtual_size]}
              type="select"
              label="Size"
              options={[
                {"Small", "small"},
                {"Medium", "medium"},
                {"Large", "large"},
                {"Huge", "huge"},
                {"Custom", "custom"}
              ]}
            />
          </div>

          <div :if={@form[:virtual_size].value != "custom"} class="flex justify-between mt-3 mb-5">
            <div class="flex items-center justify-center gap-3">
              <PC.form_label class="!mb-0" label="Storage size:" />
              <PC.h5 class="font-semibold">
                <%= @form[:storage_size].value |> Memory.format_bytes(true) || "0GB" %>
              </PC.h5>
            </div>
            <div class="flex items-center justify-center gap-3">
              <PC.form_label class="!mb-0" label="Memory limits:" />
              <PC.h5 class="font-semibold">
                <%= @form[:memory_limits].value |> Memory.format_bytes(true) %>
              </PC.h5>
            </div>
            <div class="flex items-center justify-center gap-3">
              <PC.form_label class="!mb-0" label="CPU limits:" />
              <PC.h5 class="font-semibold"><%= @form[:cpu_limits].value %></PC.h5>
            </div>
          </div>

          <div :if={@form[:virtual_size].value == "custom"} class="grid grid-cols-2 gap-6 mb-5">
            <div>
              <div class="grid grid-cols-2 gap-6">
                <div>
                  <PC.field
                    field={@form[:storage_class]}
                    type="select"
                    label="Storage Class"
                    options={@possible_storage_classes}
                  />
                </div>
                <div class="flex">
                  <div class="flex-1">
                    <PC.field disabled field={@form[:storage_size]} label="Storage Size, B" />
                  </div>
                  <div class="w-24 mt-10 mr-3 text-sm text-right text-gray-500 dark:text-gray-400">
                    <%= Memory.format_bytes(@form[:storage_size].value, true) || "0GB" %>
                  </div>
                </div>
              </div>
              <div class="grid grid-cols-2 gap-6">
                <div>
                  <PC.field
                    field={@form[:cpu_requested]}
                    type="select"
                    label="CPU Requested"
                    options={Cluster.cpu_select_options()}
                  />
                </div>
                <div>
                  <PC.field
                    field={@form[:cpu_limits]}
                    type="select"
                    label="CPU Limits"
                    options={Cluster.cpu_select_options()}
                  />
                </div>
              </div>
            </div>
            <div>
              <div class="pt-3 pb-1">
                <div class="flex justify-between w-full">
                  <%= for memory_size <- [128, 256, 512, 1024, 2048, 4096] do %>
                    <span
                      phx-click="set_storage_size_shortcut"
                      phx-value-bytes={memory_size * 1024 * 1024 * 1024}
                      phx-target={@myself}
                      class="cursor-pointer hover:underline text-sm font-medium text-gray-700 dark:text-white w-[45px] text-center"
                    >
                      <%= Memory.format_bytes(memory_size * 1024 * 1024 * 1024) %>
                    </span>
                  <% end %>
                </div>

                <PC.input
                  min="1"
                  max="256"
                  step="1"
                  field={@form[:virtual_storage_size_range_value]}
                  type="range"
                />
              </div>

              <div class="grid grid-cols-2 gap-6 mt-[22px]">
                <div>
                  <PC.field
                    field={@form[:memory_requested]}
                    type="select"
                    label="Memory Requested"
                    options={Cluster.memory_options() |> Memory.bytes_as_select_options()}
                  />
                </div>
                <div>
                  <PC.field
                    field={@form[:memory_limits]}
                    type="select"
                    label="Memory Limits"
                    options={Cluster.memory_limits_options() |> Memory.bytes_as_select_options()}
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="flex justify-between w-full py-5 border-t border-gray-300 dark:border-gray-600">
          </div>
          <div class="flex items-center gap-6">
            <div class="flex justify-between w-full lg:w-1/2">
              <PC.h5>Number of instances</PC.h5>
              <PC.h5><%= @num_instances %></PC.h5>
            </div>
            <div class="w-full lg:w-1/2">
              <PC.input min="0" max="5" step="1" field={@form[:num_instances]} type="range" />
            </div>
          </div>
        </.panel>

        <.panel class="pb-4 mb-8">
          <:title>
            Database
          </:title>

          <.inputs_for :let={database_form} field={@form[:databases]}>
            <div class="grid grid-cols-2 gap-6">
              <div>
                <PC.field field={database_form[:name]} />
              </div>
              <div>
                <PC.field field={database_form[:owner]} type="select" options={@possible_owners} />
              </div>
            </div>
          </.inputs_for>
        </.panel>

        <div class="grid grid-cols-1 gap-6 mb-8 lg:grid-cols-2">
          <.users_table
            users={Ecto.Changeset.get_field(@form[:users].form.source, :users)}
            phx_target={@myself}
          />
          <.credential_copies_table
            credential_copies={
              Ecto.Changeset.get_field(@form[:credential_copies].form.source, :credential_copies)
            }
            phx_target={@myself}
          />
        </div>
      </.form>

      <PC.modal
        :if={@pg_credential_copy_form}
        id="credential_copy_modal"
        max_width="md"
        title="New Copy Of Credentials"
        close_modal_target={@myself}
      >
        <.form for={@pg_credential_copy_form} phx-submit="add:credential_copy" phx-target={@myself}>
          <PC.field
            field={@pg_credential_copy_form[:username]}
            type="select"
            options={@possible_owners}
          />
          <PC.field
            field={@pg_credential_copy_form[:namespace]}
            type="select"
            options={@possible_namespaces}
          />
          <PC.field
            field={@pg_credential_copy_form[:format]}
            type="select"
            options={PGCredentialCopy.possible_formats()}
          />

          <div class="flex justify-end gap-4">
            <PC.button phx-target={@myself} phx-click="close_modal" type="button" color="light">
              Cancel
            </PC.button>
            <PC.button>Add copy</PC.button>
          </div>
        </.form>
      </PC.modal>

      <PC.modal
        :if={@pg_user_form}
        id="user_modal"
        max_width="md"
        title="Add user"
        close_modal_target={@myself}
      >
        <.form for={@pg_user_form} phx-submit="add:user" phx-target={@myself}>
          <PC.field field={@pg_user_form[:username]} label="User Name" />
          <PC.p class="!mt-8 !mb-6 !text-gray-500">Roles</PC.p>
          <div class="flex flex-col gap-4 mb-8">
            <.role_option
              field={@pg_user_form[:roles]}
              label="Superuser"
              help_text="A special user account used for system administration"
            />

            <.role_option
              field={@pg_user_form[:roles]}
              label="Createdb"
              help_text="This role being defined will be allowed to create new databases"
            />

            <.role_option
              field={@pg_user_form[:roles]}
              label="Createrole"
              help_text="A special user account used for system administration"
            />

            <.role_option
              field={@pg_user_form[:roles]}
              label="Inherit"
              help_text="A special user account used for system administration"
            />

            <.role_option
              field={@pg_user_form[:roles]}
              label="Login"
              help_text="A special user account used for system administration"
            />

            <.role_option
              field={@pg_user_form[:roles]}
              label="Replicatio"
              help_text="A special user account used for system administration"
            />

            <.role_option
              field={@pg_user_form[:roles]}
              label="Bypassrls"
              help_text="A special user account used for system administration"
            />
          </div>

          <div class="flex justify-end gap-4">
            <PC.button phx-target={@myself} phx-click="close_modal" type="button" color="light">
              Cancel
            </PC.button>
            <PC.button>Add user</PC.button>
          </div>
        </.form>
      </PC.modal>
    </div>
    """
  end

  defp prepare_cluster_params(cluster_params, socket) do
    cluster_params
    |> copy_embeds_from_changeset(socket.assigns.form.source)
    |> convert_storage_slider_value_to_bytes()
    |> add_default_storage_class()
  end

  defp possible_storage_classes,
    do: Enum.map(KubeServices.SystemState.SummaryStorage.storage_classes(), &get_in(&1, ["metadata", "name"]))

  defp possible_namespaces,
    do: :namespace |> KubeServices.KubeState.get_all() |> Enum.map(fn res -> get_in(res, ~w(metadata name)) end)

  defp full_name(cluster) do
    String.downcase("#{cluster.team_name}-#{cluster.name}")
  end

  defp convert_storage_slider_value_to_bytes(
         %{"virtual_storage_size_range_value" => virtual_storage_size_range_value} = params
       )
       when is_binary(virtual_storage_size_range_value) do
    bytes =
      virtual_storage_size_range_value
      |> String.to_integer()
      |> CommonCore.Util.MemorySliderConverter.slider_value_to_bytes()

    Map.put(params, "storage_size", Integer.to_string(bytes))
  end

  defp convert_storage_slider_value_to_bytes(params), do: params

  defp add_default_storage_class(params), do: Map.put_new(params, "storage_class", get_default_storage_class())

  defp copy_embeds_from_changeset(params, changeset) do
    params
    |> copy_embed(changeset, :users)
    |> copy_embed(changeset, :credential_copies)
    |> copy_embed(changeset, :databases)
  end

  defp copy_embed(params, changeset, field) do
    value =
      changeset
      |> Changeset.get_field(field, [])
      |> Enum.map(fn item ->
        item
        |> Map.from_struct()
        |> atom_keys_to_string_keys()
      end)

    Map.put(params, Atom.to_string(field), value)
  end

  defp atom_keys_to_string_keys(atom_key_map) do
    Map.new(atom_key_map, fn {k, v} -> {to_string(k), v} end)
  end

  defp get_default_storage_class do
    case KubeServices.SystemState.SummaryStorage.default_storage_class() do
      nil ->
        nil

      storage_class ->
        get_in(storage_class, ["metadata", "name"])
    end
  end
end
