defmodule ControlServerWeb.Live.KeycloakRealm do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Keycloak.ClientsTable
  import ControlServerWeb.Keycloak.UsersTable

  alias ControlServerWeb.Keycloak.NewUserForm
  alias KubeServices.Keycloak.AdminClient
  alias KubeServices.Keycloak.UserManager
  alias KubeServices.SystemState.SummaryURLs

  @impl Phoenix.LiveView
  def mount(%{} = _params, _session, socket) do
    if connected?(socket) do
      :ok = EventCenter.Keycloak.subscribe(:create_user)
    end

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
     |> assign_temp_password(nil)
     |> assign(:user_created, false)
     |> assign(:current_user, nil)}
  end

  @impl Phoenix.LiveView
  def handle_info({:user_created, user_id}, socket) do
    socket =
      socket
      |> assign(:user_created, true)
      |> assign_current_user(socket.assigns.realm_name, user_id)

    # Immediately set a temporary password for the new user
    handle_event("reset_password", %{"user-id" => user_id}, socket)
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

  defp assign_current_user(socket, name, id) do
    {:ok, user} = AdminClient.user(name, id)

    socket
    |> assign_new_user(nil)
    |> assign(:current_user, user)
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
    console_url = SummaryURLs.keycloak_console_url_for_realm(realm.realm)
    assign(socket, :realm_admin_console_url, console_url)
  end

  @impl Phoenix.LiveView
  def handle_event("new-user", _, socket) do
    {:noreply, assign_new_user(socket, %{enabled: true})}
  end

  def handle_event("edit-user", %{"user-id" => user_id}, socket) do
    {:noreply, assign_current_user(socket, socket.assigns.realm_name, user_id)}
  end

  @impl Phoenix.LiveView
  def handle_event("close_modal", _, socket) do
    {:noreply,
     socket
     |> assign_new_user(nil)
     |> assign_temp_password(nil)
     |> assign(:user_created, false)
     |> assign(:current_user, nil)}
  end

  @impl Phoenix.LiveView
  def handle_event("reset_password", %{"user-id" => user_id}, socket) do
    realm_name = socket.assigns.realm.realm

    case UserManager.reset_password(realm_name, user_id) do
      {:ok, temp_password} ->
        {:noreply, assign_temp_password(socket, temp_password)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:current_user, nil)
         |> put_flash(:global_error, reason)}
    end
  end

  def handle_event("make_realm_admin", %{"user-id" => user_id}, socket) do
    realm_name = socket.assigns.realm.realm

    case UserManager.make_realm_admin(realm_name, user_id) do
      :ok ->
        {:noreply,
         socket
         |> assign(:current_user, nil)
         |> put_flash(:global_success, "User is now a realm admin")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:current_user, nil)
         |> put_flash(:global_error, reason)}
    end
  end

  defp new_user_modal(assigns) do
    ~H"""
    <.modal show id="new-user-inner-modal" on_cancel={JS.push("close_modal")}>
      <:title>New User</:title>
      <.live_component module={NewUserForm} user={@new_user} realm={@realm_name} id="new-user-modal" />
    </.modal>
    """
  end

  defp edit_user_modal(assigns) do
    ~H"""
    <.modal show id="edit-user-modal" on_cancel={JS.push("close_modal")}>
      <:title>Editing {@user.username}</:title>

      <div class="flex items-center gap-4">
        <.button
          variant="secondary"
          icon={:key}
          phx-click="reset_password"
          data-confirm={"Are you sure you want to reset the password for #{@user.username}?"}
          phx-value-user-id={@user.id}
        >
          Reset Password
        </.button>

        <.button
          variant="secondary"
          icon={:trophy}
          phx-click="make_realm_admin"
          data-confirm={"Are you sure you want to make #{@user.username} an admin?"}
          phx-value-user-id={@user.id}
        >
          Make Realm Admin
        </.button>
      </div>
    </.modal>
    """
  end

  defp temp_password_modal(assigns) do
    ~H"""
    <.modal show id="temp-password-modal" on_cancel={JS.push("close_modal")}>
      <:title>{if @user_created, do: "New User", else: "Reset Password"}</:title>

      <p class="mb-4">
        <%= if @user_created do %>
          User has been created! Use the temporary password below to log into Keycloak. You will be prompted to change your password on the first login.
        <% else %>
          User account has been reset to the temporary password below. You will be prompted to change your password next time you login.
        <% end %>
      </p>

      <.script
        template="@src"
        src={@temp_password}
        link_url={@realm_admin_console_url}
        link_url_text="Log into Keycloak"
      />
    </.modal>
    """
  end

  defp links_panel(assigns) do
    ~H"""
    <.flex column class="justify-start">
      <.a variant="bordered" href={@realm_admin_console_url}>Admin Console</.a>
    </.flex>
    """
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.page_header title={@realm.displayName} back_link={~p"/keycloak/realms"}>
      <.badge>
        <:item label="Name">{@realm.realm}</:item>
        <:item label="ID">{@realm.id}</:item>
      </.badge>
    </.page_header>

    <.grid columns={[sm: 1, lg: 2]}>
      <.panel variant="gray" title="Details">
        <.data_list>
          <:item title="ID">
            {@realm.id}
          </:item>
          <:item title="Realm Name">
            {@realm.realm}
          </:item>
          <:item title="Display Name">
            {@realm.displayName}
          </:item>
          <:item title="Enabled">
            {@realm.enabled}
          </:item>
          <:item title="Require SSL">
            {@realm.sslRequired}
          </:item>
        </.data_list>
      </.panel>

      <.links_panel realm={@realm} realm_admin_console_url={@realm_admin_console_url} />

      <.panel class="col-span-2" title="Clients">
        <.keycloak_clients_table clients={@clients} />
      </.panel>

      <.panel class="col-span-2" title="Users">
        <:menu>
          <.button icon={:plus} phx-click="new-user">New User</.button>
        </:menu>

        <.keycloak_users_table users={@users} />
      </.panel>
    </.grid>

    <.new_user_modal :if={@new_user != nil} new_user={@new_user} realm_name={@realm.realm} />
    <.edit_user_modal :if={@current_user != nil && @temp_password == nil} user={@current_user} />
    <.temp_password_modal
      :if={@temp_password != nil}
      temp_password={@temp_password}
      realm_admin_console_url={@realm_admin_console_url}
      user_created={@user_created}
      user={@current_user}
    />
    """
  end
end
