defmodule ControlServerWeb.Live.PostgresFormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.PostgresFormSubcomponents

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGCredentialCopy
  alias CommonCore.Postgres.PGUser
  alias CommonCore.Util.Memory
  alias CommonCore.Util.MemorySliderConverter
  alias ControlServer.Postgres
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def update(%{cluster: cluster} = assigns, socket) do
    changeset =
      cluster
      |> Postgres.change_cluster()
      |> Cluster.maybe_convert_virtual_size_to_presets()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))
     |> assign(:possible_owners, possible_owners(changeset))
     |> assign(:possible_storage_classes, possible_storage_classes())
     |> assign(:possible_namespaces, possible_namespaces())
     |> assign(:possible_nodes, possible_nodes())
     |> assign(:num_instances, cluster.num_instances)
     |> assign(:pg_user_form, nil)
     |> assign(:pg_credential_copy_form, nil)
     |> assign(:storage_size_editable, false)}
  end

  @impl Phoenix.LiveComponent
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

  def handle_event("upsert:user", %{"pg_user" => pg_user_params}, %{assigns: %{form: %{source: changeset}}} = socket) do
    pg_user_changeset = PGUser.changeset(%PGUser{}, pg_user_params)

    case Ecto.Changeset.apply_action(pg_user_changeset, :validate) do
      {:ok, pg_user} ->
        position =
          if pg_user_params["position"] == "",
            do: nil,
            else: String.to_integer(pg_user_params["position"])

        users = upsert_by_position(Changeset.get_field(changeset, :users, []), pg_user, position)
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

  def handle_event("del:user", %{"username" => username}, %{assigns: %{form: %{source: changeset}}} = socket) do
    users =
      changeset
      |> Changeset.get_field(:users, [])
      |> Enum.reject(fn user -> user.username == username end)

    final_changeset = Changeset.put_embed(changeset, :users, users)

    {:noreply,
     socket
     |> assign(form: to_form(final_changeset))
     |> assign(changeset: final_changeset)
     |> assign(:possible_owners, possible_owners(final_changeset))}
  end

  def handle_event("edit:user", %{"username" => username}, %{assigns: %{form: %{source: changeset}}} = socket) do
    users = Changeset.get_field(changeset, :users)
    pg_user = Enum.find(users, &(&1.username == username))

    position =
      Enum.find_index(Changeset.get_field(changeset, :users), &(&1 == pg_user))

    pg_user_form =
      pg_user
      |> Map.put(:position, position)
      |> PGUser.changeset()
      |> to_form()

    {:noreply, assign(socket, pg_user_form: pg_user_form)}
  end

  def handle_event(
        "upsert:credential_copy",
        %{"pg_credential_copy" => pg_credential_copy_params},
        %{assigns: %{form: %{source: changeset}}} = socket
      ) do
    pg_credential_copy_changeset =
      PGCredentialCopy.changeset(%PGCredentialCopy{}, pg_credential_copy_params)

    case Ecto.Changeset.apply_action(pg_credential_copy_changeset, :validate) do
      {:ok, pg_credential_copy} ->
        position =
          if pg_credential_copy_params["position"] == "",
            do: nil,
            else: String.to_integer(pg_credential_copy_params["position"])

        credential_copies =
          upsert_by_position(
            Changeset.get_field(changeset, :credential_copies, []),
            pg_credential_copy,
            position
          )

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

  def handle_event(
        "edit:credential_copy",
        %{"username" => username, "namespace" => namespace},
        %{assigns: %{form: %{source: changeset}}} = socket
      ) do
    credential_copies = Changeset.get_field(changeset, :credential_copies)

    pg_credential_copy =
      Enum.find(
        credential_copies,
        &(&1.username == username && &1.namespace == namespace)
      )

    position =
      Enum.find_index(credential_copies, &(&1 == pg_credential_copy))

    pg_credential_copy_form =
      pg_credential_copy
      |> Map.put(:position, position)
      |> PGCredentialCopy.changeset()
      |> to_form()

    {:noreply, assign(socket, pg_credential_copy_form: pg_credential_copy_form)}
  end

  def handle_event(
        "del:credential_copy",
        %{"username" => username, "namespace" => namespace},
        %{assigns: %{form: %{source: changeset}}} = socket
      ) do
    credential_copies =
      changeset
      |> Changeset.get_field(:credential_copies, [])
      |> Enum.reject(&(&1.username == username && &1.namespace == namespace))

    final_changeset = Changeset.put_embed(changeset, :credential_copies, credential_copies)

    {:noreply,
     socket
     |> assign(form: to_form(final_changeset))
     |> assign(changeset: final_changeset)}
  end

  def handle_event("validate", %{"cluster" => cluster_params}, socket) do
    cluster_params = prepare_cluster_params(cluster_params, socket)
    {changeset, data} = Cluster.validate(socket.assigns.cluster, cluster_params)

    {:noreply,
     socket
     |> assign(form: to_form(changeset))
     |> assign(changeset: changeset)
     |> assign(possible_owners: possible_owners(changeset))
     |> assign(num_instances: data.num_instances)}
  end

  def handle_event(
        "on_change_storage_size_range",
        %{"cluster" => %{"virtual_storage_size_range_value" => virtual_storage_size_range_value}},
        socket
      ) do
    bytes = convert_storage_slider_value_to_bytes(virtual_storage_size_range_value)

    {changeset, _data} =
      Cluster.validate(socket.assigns.form.source, %{
        storage_size: bytes,
        virtual_storage_size_range_value: virtual_storage_size_range_value
      })

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("set_storage_size_shortcut", %{"bytes" => bytes}, socket) do
    virtual_storage_size_range_value =
      MemorySliderConverter.bytes_to_slider_value(String.to_integer(bytes))

    form =
      socket.assigns.form.source
      |> Changeset.put_change(:virtual_storage_size_range_value, virtual_storage_size_range_value)
      |> Changeset.put_change(:storage_size, bytes)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  # This only happens when the user is manually editing the storage size.
  # In this case, we need to update the range slider and helper text "x GB"
  def handle_event("change_storage_size", %{"cluster" => %{"storage_size" => storage_size}}, socket) do
    bytes = if storage_size == "", do: 0, else: String.to_integer(storage_size)

    virtual_storage_size_range_value =
      MemorySliderConverter.bytes_to_slider_value(bytes)

    form =
      socket.assigns.form.source
      |> Changeset.put_change(:virtual_storage_size_range_value, virtual_storage_size_range_value)
      |> Changeset.put_change(:storage_size, storage_size)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("toggle_storage_size_editable", _, socket) do
    {:noreply, assign(socket, storage_size_editable: !socket.assigns.storage_size_editable)}
  end

  def handle_event("save", %{"cluster" => cluster_params}, socket) do
    cluster_params = prepare_cluster_params(cluster_params, socket)
    save_cluster(socket, socket.assigns.action, cluster_params)
  end

  defp save_cluster(socket, :new, cluster_params) do
    case Postgres.create_cluster(cluster_params) do
      {:ok, new_cluster} ->
        socket =
          socket
          |> push_redirect(to: ~p"/postgres/#{new_cluster}/show")
          |> put_flash(:info, "Postgres Cluster created successfully")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cluster(socket, :edit, cluster_params) do
    case Postgres.update_cluster(socket.assigns.cluster, cluster_params) do
      {:ok, updated_cluster} ->
        socket =
          socket
          |> push_redirect(to: ~p"/postgres/#{updated_cluster}/show")
          |> put_flash(:info, "Postgres Cluster updated successfully")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
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
        <.page_header title={@title} back_button={%{link_type: "live_redirect", to: ~p"/postgres"}}>
          <:right_side>
            <PC.button label="Save Cluster" color="dark" phx-disable-with="Saving…" />
          </:right_side>
        </.page_header>
        <.panel class="mb-6">
          <.grid columns={[sm: 1, xl: 2]}>
            <PC.field field={@form[:name]} autofocus />
            <PC.field
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

          <div :if={@form[:virtual_size].value == "custom"} class="mb-5">
            <PC.h3>Storage</PC.h3>
            <.grid>
              <div>
                <PC.field
                  field={@form[:storage_class]}
                  type="select"
                  label="Storage Class"
                  options={@possible_storage_classes}
                />
              </div>
              <.flex>
                <div class="flex-1">
                  <.editable_field
                    field_attrs={
                      %{
                        field: @form[:storage_size],
                        label: "Storage Size",
                        type: "number",
                        "phx-change": "change_storage_size"
                      }
                    }
                    editing?={@storage_size_editable}
                    toggle_event_target={@myself}
                    toggle_event="toggle_storage_size_editable"
                    value_when_not_editing={
                      Memory.format_bytes(@form[:storage_size].value, true) || "0GB"
                    }
                  />
                </div>
                <div
                  :if={@storage_size_editable}
                  class="mt-9 mx-3 text-sm text-right text-gray-500 dark:text-gray-400 w-16"
                >
                  <%= Memory.format_bytes(@form[:storage_size].value, true) || "0GB" %>
                </div>
              </.flex>
              <div class="pt-3 pb-1 mb-[22px] lg:col-span-2">
                <.flex class="justify-between w-full">
                  <%= for memory_size <- MemorySliderConverter.control_points() do %>
                    <span
                      phx-click="set_storage_size_shortcut"
                      phx-value-bytes={memory_size}
                      phx-target={@myself}
                      class="cursor-pointer hover:underline text-sm font-medium text-gray-700 dark:text-white w-[45px] text-center"
                    >
                      <%= Memory.format_bytes(memory_size) %>
                    </span>
                  <% end %>
                </.flex>

                <PC.input
                  min="1"
                  max="120"
                  step="1"
                  phx-change="on_change_storage_size_range"
                  field={@form[:virtual_storage_size_range_value]}
                  type="range"
                />
              </div>
            </.grid>

            <PC.h3>Running Limits</PC.h3>
            <.grid>
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
            </.grid>
          </div>

          <.flex class="justify-between w-full py-5 border-t border-gray-300 dark:border-gray-600">
          </.flex>

          <.flex class="items-center">
            <.flex class="justify-between w-full lg:w-1/2">
              <.h5>Number of instances</.h5>
              <div class="font-bold text-4xl text-primary-500"><%= @num_instances %></div>
            </.flex>
            <.flex class="w-full lg:w-1/2">
              <PC.input
                min="1"
                max={max(length(@possible_nodes || []), 3)}
                step="1"
                field={@form[:num_instances]}
                type="range"
              />
            </.flex>
          </.flex>
        </.panel>

        <.panel class="pb-4 mb-8" title="Database">
          <.inputs_for :let={database_form} field={@form[:databases]}>
            <.grid columns={%{sm: 1, lg: 2}}>
              <div>
                <PC.field field={database_form[:name]} />
              </div>
              <div>
                <PC.field field={database_form[:owner]} type="select" options={@possible_owners} />
              </div>
            </.grid>
          </.inputs_for>
        </.panel>

        <.grid columns={%{sm: 1, lg: 2}} class="mb-8">
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
        </.grid>
      </.form>

      <.user_form_modal phx_target={@myself} user_form={@pg_user_form} />

      <.credential_copy_form_modal
        phx_target={@myself}
        credential_copy_form={@pg_credential_copy_form}
        possible_owners={@possible_owners}
        possible_namespaces={@possible_namespaces}
        possible_formats={PGCredentialCopy.possible_formats()}
      />
    </div>
    """
  end

  defp prepare_cluster_params(cluster_params, socket) do
    cluster_params
    |> copy_embeds_from_changeset(socket.assigns.form.source)
    |> add_default_storage_class()
  end

  defp possible_storage_classes,
    do: Enum.map(KubeServices.SystemState.SummaryStorage.storage_classes(), &get_in(&1, ["metadata", "name"]))

  defp possible_namespaces,
    do: :namespace |> KubeServices.KubeState.get_all() |> Enum.map(fn res -> get_in(res, ~w(metadata name)) end)

  defp possible_nodes,
    do: :node |> KubeServices.KubeState.get_all() |> Enum.map(fn res -> get_in(res, ~w(metadata name)) end)

  defp convert_storage_slider_value_to_bytes(range_value) when is_binary(range_value) do
    if range_value == "" do
      0
    else
      range_value
      |> String.to_integer()
      |> MemorySliderConverter.slider_value_to_bytes()
    end
  end

  defp convert_storage_slider_value_to_bytes(_), do: 1

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

  defp upsert_by_position(list, item, position) when is_integer(position) do
    List.replace_at(list, position, item)
  end

  defp upsert_by_position(list, item, _) do
    list ++ [item]
  end
end
