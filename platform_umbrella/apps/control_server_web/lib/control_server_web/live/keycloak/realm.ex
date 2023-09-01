defmodule ControlServerWeb.Live.KeycloakRealm do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  import CommonUI.Modal
  import ControlServerWeb.Keycloak.ClientsTable
  import ControlServerWeb.Keycloak.UsersTable

  alias CommonCore.Keycloak.AdminClient
  alias ControlServerWeb.Keycloak.NewUserForm
  alias KubeServices.SystemState.SummaryHosts

  @impl Phoenix.LiveView
  def mount(%{} = _params, _session, socket) do
    :ok = EventCenter.Keycloak.subscribe(:create_user)
    {:ok, assign_keycloak_url(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"name" => name} = _params, _uri, socket) do
    {:noreply,
     socket
     |> assign_realm(name)
     |> assign_clients(name)
     |> assign_users(name)
     |> assign_new_user(nil)}
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    name = socket.assigns.realm.realm

    # Refresh everything
    #
    # Dont set the new_user to nil because we don't want
    # to close on a new user event that we caused.
    {:noreply,
     socket
     |> assign_realm(name)
     |> assign_clients(name)
     |> assign_users(name)}
  end

  defp assign_realm(socket, name) do
    {:ok, realm} = AdminClient.realm(name)

    socket
    |> assign(:realm_name, name)
    |> assign(:realm, realm)
  end

  defp assign_clients(socket, name) do
    {:ok, clients} = AdminClient.clients(name)
    assign(socket, :clients, clients)
  end

  defp assign_users(socket, name) do
    {:ok, users} = AdminClient.users(name)
    assign(socket, :users, users)
  end

  defp assign_keycloak_url(socket) do
    assign(socket, :keycloak_url, "http://" <> SummaryHosts.keycloak_host())
  end

  defp assign_new_user(socket, user) do
    assign(socket, :new_user, user)
  end

  @impl Phoenix.LiveView
  def handle_event("new-user", _, socket) do
    {:noreply, assign_new_user(socket, %{enabled: true})}
  end

  @impl Phoenix.LiveView
  def handle_event("cancel_user", _, socket) do
    {:noreply, assign_new_user(socket, nil)}
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.h1>
      Keycloak Realm
      <:sub_header><%= @realm.displayName %></:sub_header>
    </.h1>
    <.card>
      <.data_list>
        <:item title="ID"><%= @realm.id %></:item>
        <:item title="Name"><%= @realm.realm %></:item>
        <:item title="Display Name"><%= @realm.displayName %></:item>
      </.data_list>
    </.card>

    <.h2>Clients</.h2>
    <.keycloak_clients_table clients={@clients} />
    <.h2>Users</.h2>
    <.keycloak_users_table users={@users} />

    <div :if={@new_user != nil}>
      <.modal on_cancel={JS.push("cancel_user")} id="new-user-inner-modal" show={true}>
        <.live_component
          module={NewUserForm}
          user={@new_user}
          realm={@realm.realm}
          id="new-user-modal"
        />
      </.modal>
    </div>
    <.button phx-click="new-user">New User</.button>
    """
  end
end
