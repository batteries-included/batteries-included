defmodule ControlServerWeb.Live.PostgresFormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGUser
  alias ControlServer.Postgres
  alias ControlServerWeb.PostgresFormSubcomponents
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def update(%{cluster: cluster} = assigns, socket) do
    changeset =
      Postgres.change_cluster(cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))
     |> assign(:possible_owners, possible_owners(changeset))
     |> assign_possible_namespaces()
     |> assign_possible_nodes()
     |> assign_possible_storage_classes()
     |> assign_projects()
     |> assign(:num_instances, cluster.num_instances)
     |> assign(:pg_user_form, nil)}
  end

  defp assign_projects(socket) do
    projects = ControlServer.Projects.list_projects()
    assign(socket, projects: projects)
  end

  defp assign_possible_nodes(socket) do
    possible_nodes = possible_nodes()
    assign(socket, possible_nodes: possible_nodes)
  end

  defp assign_possible_namespaces(socket) do
    possible_namespaces = possible_namespaces()
    assign(socket, possible_namespaces: possible_namespaces)
  end

  defp assign_possible_storage_classes(socket) do
    possible_storage_classes = possible_storage_classes()
    assign(socket, possible_storage_classes: possible_storage_classes)
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_modal", _, socket) do
    {:noreply, assign(socket, pg_user_form: nil)}
  end

  def handle_event("toggle_user_modal", _, socket) do
    pg_user_form =
      %PGUser{username: "", roles: ["login"], credential_namespaces: ["battery-data"]}
      |> PGUser.changeset()
      |> to_form()

    {:noreply, assign(socket, pg_user_form: pg_user_form)}
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

  def handle_event("validate:user", %{"pg_user" => params}, socket) do
    form =
      %PGUser{}
      |> PGUser.changeset(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :pg_user_form, form)}
  end

  def handle_event("validate", %{"cluster" => cluster_params}, socket) do
    cluster_params = prepare_cluster_params(cluster_params, socket)

    changeset =
      socket.assigns.cluster
      |> Cluster.changeset(cluster_params)
      |> Map.put(:action, :validate)

    data = Ecto.Changeset.apply_changes(changeset)

    {:noreply,
     socket
     |> assign(form: to_form(changeset))
     |> assign(possible_owners: possible_owners(changeset))
     |> assign(num_instances: data.num_instances)}
  end

  def handle_event("change_storage_size_range", %{"value" => tick_value}, socket) do
    handle_event(
      "change_storage_size_range",
      %{"cluster" => %{"virtual_storage_size_range_value" => tick_value}},
      socket
    )
  end

  def handle_event(
        "change_storage_size_range",
        %{"cluster" => %{"virtual_storage_size_range_value" => range_value}},
        socket
      ) do
    changeset =
      socket.assigns.cluster
      |> Cluster.changeset(socket.assigns.form.source.params)
      |> Cluster.put_storage_size(range_value)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
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
          |> put_flash(:global_success, "Postgres Cluster created successfully")
          |> push_redirect(to: ~p"/postgres/#{new_cluster}/show")

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
          |> put_flash(:global_success, "Postgres Cluster updated successfully")
          |> push_redirect(to: ~p"/postgres/#{updated_cluster}/show")

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
    existing_owner =
      (Changeset.get_field(changeset, :database, %{owner: nil}) || %{owner: nil}).owner

    usernames
    |> Enum.concat([existing_owner])
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
        novalidate
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
        <.page_header title={@title} back_link={~p"/postgres"}>
          <.button variant="dark" type="submit" phx-disable-with="Saving…">Save Cluster</.button>
        </.page_header>

        <.flex column>
          <.panel>
            <PostgresFormSubcomponents.size_form
              form={@form}
              phx_target={@myself}
              ticks={Cluster.storage_range_ticks()}
            />

            <.grid columns={[sm: 1, lg: 2]} class="items-center">
              <.h5>Number of instances</.h5>
              <.input
                field={@form[:num_instances]}
                type="range"
                min="1"
                max={max(length(@possible_nodes || []), 3)}
                step="1"
              />
            </.grid>
          </.panel>

          <PostgresFormSubcomponents.users_table
            users={Ecto.Changeset.get_field(@form[:users].form.source, :users)}
            phx_target={@myself}
          />

          <.grid columns={%{sm: 1, lg: 2}}>
            <.panel title="Database">
              <.inputs_for :let={database_form} field={@form[:database]}>
                <.grid columns={%{sm: 1, lg: 2}}>
                  <div>
                    <.input label="Name" field={database_form[:name]} />
                  </div>
                  <div>
                    <.input
                      label="Owner"
                      field={database_form[:owner]}
                      type="select"
                      placeholder="Select Database Owner (on creation)"
                      options={@possible_owners}
                    />
                  </div>
                </.grid>
              </.inputs_for>
            </.panel>

            <.panel title="Advanced Settings" variant="gray">
              <.flex column>
                <.input
                  label="Project"
                  field={@form[:project_id]}
                  type="select"
                  placeholder="Choose Project"
                  placeholder_selectable={true}
                  options={Enum.map(@projects, &{&1.name, &1.id})}
                />
              </.flex>
            </.panel>
          </.grid>
        </.flex>
      </.form>

      <PostgresFormSubcomponents.user_form_modal
        phx_target={@myself}
        user_form={@pg_user_form}
        possible_namespaces={@possible_namespaces}
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

  defp add_default_storage_class(params), do: Map.put_new(params, "storage_class", get_default_storage_class())

  defp copy_embeds_from_changeset(params, changeset) do
    copy_embed(params, changeset, :users)
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

  defp atom_keys_to_string_keys(atom_key_map) when is_struct(atom_key_map) do
    atom_key_map |> Map.from_struct() |> atom_keys_to_string_keys()
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
