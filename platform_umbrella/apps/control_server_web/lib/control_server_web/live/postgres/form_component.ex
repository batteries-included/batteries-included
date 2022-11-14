defmodule ControlServerWeb.Live.PostgresFormComponent do
  use ControlServerWeb, :live_component

  import Phoenix.HTML.Form, only: [inputs_for: 2]

  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster
  alias ControlServer.Postgres.PGUser
  alias ControlServer.Postgres.PGDatabase

  alias Ecto.Changeset

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "cluster:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  @impl true
  def update(%{cluster: cluster} = assigns, socket) do
    changeset = Postgres.change_cluster(cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:possible_owners, possible_owners(changeset))
     |> assign(:full_name, full_name(cluster))
     |> assign(:num_instances, cluster.num_instances)}
  end

  defp full_name(cluster) do
    "#{cluster.team_name}-#{cluster.name}"
  end

  def handle_event("add:user", _, %{assigns: %{changeset: changeset}} = socket) do
    users =
      Changeset.get_field(changeset, :users, []) ++ [%PGUser{username: "user", roles: ["login"]}]

    final_changeset = Changeset.put_embed(changeset, :users, users)

    {:noreply,
     socket
     |> assign(changeset: final_changeset)
     |> assign(:possible_owners, possible_owners(final_changeset))}
  end

  def handle_event("del:user", %{"idx" => idx}, %{assigns: %{changeset: changeset}} = socket) do
    users = changeset |> Changeset.get_field(:users, []) |> List.delete_at(String.to_integer(idx))

    final_changeset = Changeset.put_embed(changeset, :users, users)

    {:noreply,
     socket
     |> assign(changeset: final_changeset)
     |> assign(:possible_owners, possible_owners(final_changeset))}
  end

  def handle_event("add:database", _, %{assigns: %{changeset: changeset}} = socket) do
    databases = Changeset.get_field(changeset, :databases, []) ++ [%PGDatabase{}]

    final_changeset = Changeset.put_embed(changeset, :databases, databases)

    {:noreply,
     socket
     |> assign(changeset: final_changeset)
     |> assign(:possible_owners, possible_owners(final_changeset))}
  end

  def handle_event("del:database", %{"idx" => idx}, %{assigns: %{changeset: changeset}} = socket) do
    databases =
      changeset |> Changeset.get_field(:databases, []) |> List.delete_at(String.to_integer(idx))

    final_changeset = Changeset.put_embed(changeset, :databases, databases)

    {:noreply,
     socket
     |> assign(changeset: final_changeset)
     |> assign(:possible_owners, possible_owners(final_changeset))}
  end

  @impl true
  def handle_event("validate", %{"cluster" => params}, socket) do
    {changeset, data} = Cluster.validate(params)

    {:noreply,
     socket
     |> assign(changeset: changeset)
     |> assign(:possible_owners, possible_owners(changeset))
     |> assign(:full_name, full_name(data))
     |> assign(:num_instances, data.num_instances)}
  end

  def handle_event("save", %{"cluster" => cluster_params}, socket) do
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
        {:noreply, assign(socket, changeset: changeset)}
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
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp send_info(socket, nil, _cluster), do: {:noreply, socket}

  defp send_info(socket, target, cluster) do
    send(target, {socket.assigns.save_info, %{"cluster" => cluster}})
    socket
  end

  def users_form(assigns) do
    ~H"""
    <.h2 class="col-span-2 mt-16">Users</.h2>
    <div class="sm:col-span-2">
      <div class="grid grid-cols-12 gap-y-6 gap-x-4">
        <%= for user_form <- inputs_for(@form, :users) do %>
          <div class="col-span-4">
            <.input field={{user_form, :username}} label="Username" />
          </div>
          <div class="col-span-7">
            <.input
              field={{user_form, :roles}}
              label="Roles"
              type="select"
              multiple={true}
              options={PGUser.possible_roles()}
            />
          </div>
          <div class="col-span-1">
            <.link
              phx-click="del:user"
              phx-value-idx={user_form.index}
              phx-target={@target}
              class="text-sm"
              type="styled"
            >
              <Heroicons.trash class="w-7 h-7 mx-auto mt-8" />
            </.link>
          </div>
        <% end %>

        <.link
          phx-click="add:user"
          phx-target={@target}
          class="pt-5 text-lg col-span-12"
          type="styled"
        >
          Add User
        </.link>
      </div>
    </div>
    """
  end

  def databases_form(assigns) do
    ~H"""
    <.h2 class="col-span-2 mt-16">Databases</.h2>
    <div class="sm:col-span-2">
      <div class="grid grid-cols-12 gap-y-6 gap-x-4">
        <%= for database_form <- inputs_for(@form, :databases) do %>
          <div class="col-span-4">
            <.input field={{database_form, :name}} label="Name" />
          </div>
          <div class="col-span-7">
            <.input
              field={{database_form, :owner}}
              label="Owner"
              type="select"
              options={@possible_owners}
            />
          </div>
          <div class="col-span-1">
            <.link
              phx-click="del:database"
              phx-value-idx={database_form.index}
              phx-target={@target}
              class="text-sm"
              type="styled"
            >
              <Heroicons.trash class="w-7 h-7 mx-auto mt-8" />
            </.link>
          </div>
        <% end %>

        <.link
          phx-click="add:database"
          phx-target={@target}
          class="pt-5 text-lg col-span-12"
          type="styled"
        >
          Add Database
        </.link>
      </div>
    </div>
    """
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

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@changeset}
        id="cluster-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.input field={{f, :name}} />
        <div class="sm:col-span-1">
          <.labeled_definition title="Service Name" contents={@full_name} />
        </div>
        <.input
          min={1}
          max={5}
          type="range"
          field={{f, :num_instances}}
          placeholder="Number of Instances"
        />
        <div class="sm:col-span-1">
          <.labeled_definition title="Number of Instances" contents={@num_instances} />
        </div>
        <.input field={{f, :storage_size}} placeholder="Storage Size" />
        <.users_form form={f} target={@myself} />
        <.databases_form form={f} target={@myself} possible_owners={@possible_owners} />

        <:actions>
          <.button type="submit" phx-disable-with="Saving…">
            Save
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
