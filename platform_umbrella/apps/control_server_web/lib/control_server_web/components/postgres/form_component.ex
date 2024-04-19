defmodule ControlServerWeb.Live.PostgresFormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component
  use ControlServerWeb.PostgresFormSubcomponents

  import ControlServerWeb.PostgresFormSubcomponents

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGUser
  alias ControlServer.Postgres
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
     |> assign(:possible_storage_classes, possible_storage_classes())
     |> assign(:possible_namespaces, possible_namespaces())
     |> assign(:possible_nodes, possible_nodes())
     |> assign(:num_instances, cluster.num_instances)
     |> assign(:pg_user_form, nil)}
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

  def handle_event("change:credential_namespaces", params, socket) do
    value = params |> Map.get("_target") |> List.last()
    changeset = socket.assigns.pg_user_form.source
    namespaces = changeset |> Changeset.get_field(:credential_namespaces) |> toggle_namespace(value)

    form =
      changeset
      |> Changeset.put_change(:credential_namespaces, namespaces)
      |> to_form()

    {:noreply, assign(socket, :pg_user_form, form)}
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

  defp toggle_namespace(namespaces, value) do
    without = Enum.reject(namespaces, &(&1 == value))

    if length(without) < length(namespaces) do
      without
    else
      [value | namespaces]
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
      Changeset.get_field(changeset, :database, %{owner: nil}).owner

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
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
        <.page_header title={@title} back_link={~p"/postgres"}>
          <.button variant="dark" type="submit" phx-disable-with="Saving…">Save Cluster</.button>
        </.page_header>

        <.flex column>
          <.panel>
            <.size_form form={@form} phx_target={@myself} />

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

          <.users_table
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

            <.panel title="Advanced Settings" variant="gray"></.panel>
          </.grid>
        </.flex>
      </.form>

      <.user_form_modal
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
    params
    |> copy_embed(changeset, :users)
    |> copy_single_embed(changeset, :database)
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

  defp copy_single_embed(params, changeset, field) do
    value =
      changeset
      |> Changeset.get_field(field, %{})
      |> atom_keys_to_string_keys()

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
