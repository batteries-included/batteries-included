defmodule ControlServerWeb.Live.KeycloakRealm do
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias KubeServices.SystemState.SummaryHosts
  alias KubeServices.Keycloak.AdminClient

  import ControlServerWeb.Keycloak.UsersTable
  import ControlServerWeb.Keycloak.ClientsTable

  @good_keys ~w(id displayName realm)

  @impl Phoenix.LiveView
  def mount(%{} = _params, _session, socket) do
    {:ok, assign_keycloak_url(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"name" => name} = _params, _uri, socket) do
    {:noreply, socket |> assign_realm(name) |> assign_clients(name) |> assign_users(name)}
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

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.h1>
      Keycloak Realm
      <:sub_header><%= display_name(@realm) %></:sub_header>
    </.h1>
    <.card>
      <.data_list>
        <:item :for={{key, value} <- display_map(@realm)} title={key}>
          <%= value %>
        </:item>
      </.data_list>
    </.card>

    <.h2>Clients</.h2>
    <.keycloak_clients_table clients={@clients} />
    <.h2>Users</.h2>
    <.keycloak_users_table users={@users} />
    """
  end

  defp display_name(realm), do: Map.get(realm, "displayName")

  defp display_map(realm), do: Map.take(realm, @good_keys)
end
