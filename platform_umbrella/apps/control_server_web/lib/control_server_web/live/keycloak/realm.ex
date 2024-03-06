defmodule ControlServerWeb.Live.KeycloakRealm do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Keycloak.ClientsTable
  import ControlServerWeb.Keycloak.UsersTable

  alias CommonCore.Keycloak.AdminClient
  alias ControlServerWeb.Keycloak.NewUserForm
  alias KubeServices.Keycloak.UserManager
  alias KubeServices.SystemState.SummaryURLs

  @impl Phoenix.LiveView
  def mount(%{} = _params, _session, socket) do
    :ok = EventCenter.Keycloak.subscribe(:create_user)
    {:ok, socket |> assign_keycloak_url() |> assign_current_page()}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"name" => name} = _params, _uri, socket) do
    {:noreply,
     socket
     |> assign_realm(name)
     |> assign_clients(name)
     |> assign_users(name)
     |> assign_realm_admin_console_url()
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
     |> assign_users(name)
     |> assign_realm_admin_console_url()}
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
    assign(socket, :keycloak_url, SummaryURLs.url_for_battery(:keycloak))
  end

  defp assign_new_user(socket, user) do
    assign(socket, :new_user, user)
  end

  defp assign_temp_password(socket, temp_password) do
    assign(socket, :temp_password, temp_password)
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, :net_sec)
  end

  defp assign_realm_admin_console_url(%{assigns: %{realm: realm}} = socket) do
    assign(socket, :realm_admin_console_url, SummaryURLs.keycloak_console_url_for_realm(realm.realm))
  end

  @impl Phoenix.LiveView
  def handle_event("new-user", _, socket) do
    {:noreply, assign_new_user(socket, %{enabled: true})}
  end

  @impl Phoenix.LiveView
  def handle_event("close_modal", _, socket) do
    {:noreply, socket |> assign_new_user(nil) |> assign_temp_password(nil)}
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

  def handle_event("make_realm_admin", %{"user-id" => user_id}, socket) do
    realm_name = socket.assigns.realm.realm

    case UserManager.make_realm_admin(realm_name, user_id) do
      :ok ->
        {:noreply, socket}

      {:error, _reason} ->
        # Ignore for now
        #
        # TODO(elliott): when we figure out flash/temporary messaging
        # use that here for error reporting.
        {:noreply, socket}
    end
  end

  defp new_user_modal(assigns) do
    ~H"""
    <PC.modal id="new-user-inner-modal" show={true}>
      <.live_component module={NewUserForm} user={@new_user} realm={@realm_name} id="new-user-modal" />
    </PC.modal>
    """
  end

  defp temp_password_modal(assigns) do
    ~H"""
    <PC.modal id="temp-password-modal" show={true}>
      <.h2>Temporary Password Set</.h2>
      A new password has been set for this user. The temporary password is: <pre><%= @temp_password %></pre>
    </PC.modal>
    """
  end

  defp links_panel(assigns) do
    ~H"""
    <.flex column class="justify-start">
      <.bordered_menu_item href={@realm_admin_console_url} title="Admin Console" />
    </.flex>
    """
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.page_header title={@realm.displayName} back_link={~p"/keycloak/realms"}>
      <:menu>
        <.data_horizontal_bordered>
          <:item title="Name"><%= @realm.realm %></:item>
          <:item title="ID"><%= @realm.id %></:item>
        </.data_horizontal_bordered>
      </:menu>
    </.page_header>
    <.grid columns={[sm: 1, lg: 2]}>
      <.panel variant="gray" title="Details">
        <.data_list>
          <:item title="ID">
            <%= @realm.id %>
          </:item>
          <:item title="Realm Name">
            <%= @realm.realm %>
          </:item>
          <:item title="Display Name">
            <%= @realm.displayName %>
          </:item>
          <:item title="Enabled">
            <%= @realm.enabled %>
          </:item>
          <:item title="Require SSL">
            <%= @realm.sslRequired %>
          </:item>
        </.data_list>
      </.panel>
      <.links_panel realm={@realm} realm_admin_console_url={@realm_admin_console_url} />
      <.panel class="col-span-2" title="Clients">
        <.keycloak_clients_table clients={@clients} />
      </.panel>
      <.panel class="col-span-2" title="Users">
        <:menu>
          <.button variant="secondary" phx-click="new-user">New User</.button>
        </:menu>
        <.keycloak_users_table users={@users} />
      </.panel>
    </.grid>

    <.new_user_modal :if={@new_user != nil} new_user={@new_user} realm_name={@realm.realm} />
    <.temp_password_modal :if={@temp_password != nil} temp_password={@temp_password} />
    """
  end
end
