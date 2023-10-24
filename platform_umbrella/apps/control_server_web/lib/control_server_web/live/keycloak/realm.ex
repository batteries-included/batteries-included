defmodule ControlServerWeb.Live.KeycloakRealm do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonUI.Modal
  import ControlServerWeb.Keycloak.ClientsTable
  import ControlServerWeb.Keycloak.UsersTable

  alias CommonCore.Keycloak.AdminClient
  alias ControlServerWeb.Keycloak.NewUserForm
  alias KubeServices.Keycloak.UserManager
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
     |> assign_new_user(nil)
     |> assign_temp_password(nil)}
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

  defp assign_temp_password(socket, temp_password) do
    assign(socket, :temp_password, temp_password)
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
  def handle_event("reset_password", %{"user-id" => user_id}, socket) do
    realm_name = socket.assigns.realm.realm

    case UserManager.reset_password(realm_name, user_id) do
      {:ok, temp_password} ->
        {:noreply, assign_temp_password(socket, temp_password)}

      {:error, _reason} ->
        # Ignore for now
        #
        # TODO(elliott): when we figure out flash/temporary messaging
        # use that here for error reporting.
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("cancel_temp_password", _, socket) do
    {:noreply, assign_temp_password(socket, nil)}
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.page_header
      title="Keycloak Realm"
      back_button={%{link_type: "live_redirect", to: ~p"/keycloak/realms"}}
    />
    <.panel>
      <:title><%= @realm.displayName %></:title>
      <.data_list>
        <:item title="ID"><%= @realm.id %></:item>
        <:item title="Name"><%= @realm.realm %></:item>
      </.data_list>
    </.panel>

    <.panel class="mt-5">
      <:title>Users</:title>
      <.keycloak_clients_table clients={@clients} />
    </.panel>
    <.panel class="mt-5">
      <:title>Users</:title>
      <:top_right>
        <PC.button phx-click="new-user">New User</PC.button>
      </:top_right>
      <.keycloak_users_table users={@users} />
    </.panel>

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

    <div :if={@temp_password != nil}>
      <.modal on_cancel={JS.push("cancel_temp_password")} id="temp-password-modal" show={true}>
        <.h2>Temporary Password Set</.h2>
        A new password has been set for this user. The temporary password is: <pre><%= @temp_password %></pre>
      </.modal>
    </div>
    """
  end
end
