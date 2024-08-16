defmodule KubeServices.Keycloak.AdminClient do
  @moduledoc false
  use GenServer
  use TypedStruct

  import CommonCore.Util.Tesla

  alias CommonCore.OpenAPI.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.CredentialRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.GroupRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RealmRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RoleRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.UserRepresentation
  alias KubeServices.Keycloak.TokenStrategy
  alias KubeServices.Keycloak.WellknownClient

  require Logger

  @state_opts ~w(username password realm client_id)a

  @me __MODULE__

  typedstruct module: State do
    field :username, String.t()
    field :password, String.t()

    # We use the root realm with our admin client
    # since that's the only thing that's guaranteed to exist.
    field :realm, String.t(), default: "master"
    # Admin cli is the best client that's guaranteed to exist.
    field :client_id, String.t(), default: "admin-cli"

    field :token, OAuth2.AccessToken.t(), enforce: false, default: nil
    field :authorization_url, String.t(), enforce: false, default: nil
    field :token_url, String.t(), enforce: false, default: nil
  end

  def start_link(opts \\ []) do
    {state_opts, server_opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, server_opts)
  end

  @impl GenServer
  def init(opts) do
    state = struct!(State, opts)
    Logger.info("Starting KubeSerivces.Keycloak.AdminClient", realm: state.realm)
    {:ok, state}
  end

  #
  # Realms
  #
  @spec realms(atom | pid | {atom, any} | {:via, atom, any}) ::
          {:ok, list(RealmRepresentation.t())} | {:error, any()}
  @doc """
  List the realms on Keycloak

  This is a rest call into the api server.
  """
  def realms(target \\ @me) do
    GenServer.call(target, :realms)
  end

  @spec realm(atom | pid | {atom, any} | {:via, atom, any}, any) ::
          {:ok, RealmRepresentation.t()} | {:error, any()}
  @doc """
  Get the realm representation from Keycloak

  This is a rest call into the api server.
  """
  def realm(target \\ @me, name) do
    GenServer.call(target, {:realm, name})
  end

  @spec create_realm(atom | pid | {atom, any} | {:via, atom, any}, map()) :: {:ok, String.t()} | {:error, any()}
  @doc """
  Given a realm representation create it.
  """
  def create_realm(target \\ @me, realm) do
    GenServer.call(target, {:create_realm, realm})
  end

  #
  # Clients
  #
  @spec clients(atom | pid | {atom, any} | {:via, atom, any}, String.t()) ::
          {:ok, list(ClientRepresentation.t())} | {:error, any()}
  def clients(target \\ @me, realm_name) do
    GenServer.call(target, {:clients, realm_name})
  end

  @spec client(atom | pid | {atom, any} | {:via, atom, any}, String.t(), String.t()) ::
          {:ok, ClientRepresentation.t()} | {:error, any()}
  def client(target \\ @me, realm_name, client_id) do
    GenServer.call(target, {:client, realm_name, client_id})
  end

  @spec create_client(
          atom | pid | {atom, any} | {:via, atom, any},
          String.t(),
          ClientRepresentation.t() | map()
        ) :: {:ok, String.t()} | {:error, any()}
  def create_client(target \\ @me, realm_name, client_data) do
    GenServer.call(target, {:create_client, realm_name, client_data})
  end

  @spec update_client(
          atom | pid | {atom, any} | {:via, atom, any},
          String.t(),
          ClientRepresentation.t() | map()
        ) :: {:ok, String.t()} | {:error, any()}
  def update_client(target \\ @me, realm_name, client_data)

  def update_client(target, realm_name, %{id: client_id} = client_data) do
    GenServer.call(target, {:update_client, realm_name, client_id, client_data})
  end

  def update_client(target, realm_name, %{"id" => client_id} = client_data) do
    GenServer.call(target, {:update_client, realm_name, client_id, client_data})
  end

  #
  # Users
  #
  @spec users(atom | pid | {atom, any} | {:via, atom, any}, String.t()) ::
          {:ok, list(UserRepresentation.t())} | {:error, any()}
  def users(target \\ @me, realm_name) do
    GenServer.call(target, {:users, realm_name})
  end

  @spec user(atom | pid | {atom, any} | {:via, atom, any}, String.t(), String.t()) ::
          {:ok, UserRepresentation.t()} | {:error, any()}
  def user(target \\ @me, realm_name, user_id) do
    GenServer.call(target, {:user, realm_name, user_id})
  end

  @spec create_user(
          atom | pid | {atom, any} | {:via, atom, any},
          String.t(),
          UserRepresentation.t()
        ) ::
          {:ok, UserRepresentation.t()} | {:error, any()}
  def create_user(target \\ @me, realm_name, user_data) do
    GenServer.call(target, {:create_user, realm_name, user_data})
  end

  @spec update_user(atom | pid | {atom, any} | {:via, atom, any}, String.t(), map()) :: any
  def update_user(target \\ @me, realm_name, user_data)

  def update_user(target, realm_name, %{id: user_id} = user_data) do
    GenServer.call(target, {:update_user, realm_name, user_id, user_data})
  end

  def update_user(target, realm_name, %{"id" => user_id} = user_data) do
    GenServer.call(target, {:update_user, realm_name, user_id, user_data})
  end

  @spec delete_user(atom | pid | {atom, any} | {:via, atom, any}, String.t(), String.t() | map()) :: any
  def delete_user(target \\ @me, realm_name, id_or_user_data)

  def delete_user(target, realm_name, %{id: user_id}) do
    delete_user(target, realm_name, user_id)
  end

  def delete_user(target, realm_name, %{"id" => user_id}) do
    delete_user(target, realm_name, user_id)
  end

  def delete_user(target, realm_name, user_id) do
    GenServer.call(target, {:delete_user, realm_name, user_id})
  end

  @spec reset_password_user(
          atom | pid | {atom, any} | {:via, atom, any},
          String.t(),
          String.t(),
          CredentialRepresentation.t() | map()
        ) :: any
  def reset_password_user(target \\ @me, realm_name, user_id, creds) do
    GenServer.call(target, {:reset_password_user, realm_name, user_id, creds})
  end

  #
  # Groups
  #
  @spec groups(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, String.t()) ::
          {:ok, list(GroupRepresentation.t())} | {:error, any()}
  def groups(target \\ @me, realm_name) do
    GenServer.call(target, {:groups, realm_name})
  end

  #
  # Roles
  #
  @spec roles(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, String.t()) ::
          {:ok, list(RoleRepresentation.t())} | {:error, any()}
  def roles(target \\ @me, realm_name) do
    GenServer.call(target, {:roles, realm_name})
  end

  @spec client_roles(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, String.t(), String.t()) ::
          {:ok, list(RoleRepresentation.t())} | {:error, any()}
  def client_roles(target \\ @me, realm_name, client_id) do
    GenServer.call(target, {:client_roles, realm_name, client_id})
  end

  @spec add_client_roles(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, String.t(), binary(), binary(), list()) ::
          {:ok, any()} | {:error, any()}
  def add_client_roles(target \\ @me, realm_name, user_id, client_id, roles_payload) do
    GenServer.call(target, {:add_client_roles, realm_name, user_id, client_id, roles_payload})
  end

  #
  # Genserver Implementation
  #

  @impl GenServer
  def handle_call(request, _from, state) do
    case to_client(state) do
      {%{} = client, %State{} = new_state} ->
        {:reply, run(request, client), new_state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp run(:realms, client) do
    client
    |> get("/admin/realms")
    |> to_result(&RealmRepresentation.new!/1)
  end

  defp run({:realm, name}, client) do
    client
    |> get("/admin/realms/#{name}")
    |> to_result(&RealmRepresentation.new!/1)
  end

  defp run({:create_realm, realm}, client) do
    client
    |> OAuth2.Client.put_header("content-type", "application/json")
    |> OAuth2.Client.post("/admin/realms", realm)
    |> to_result(nil)
  end

  # TODO Add on UPDATE realm

  defp run({:clients, realm_name}, client) do
    client
    |> get("/admin/realms/#{realm_name}/clients")
    |> to_result(&ClientRepresentation.new!/1)
  end

  defp run({:client, realm_name, client_id}, client) do
    client
    |> get("/admin/realms/#{realm_name}/clients/#{client_id}")
    |> to_result(&ClientRepresentation.new!/1)
  end

  defp run({:create_client, realm_name, client_data}, client) do
    client
    |> post("/admin/realms/#{realm_name}/clients", client_data)
    |> to_result(nil)
  end

  defp run({:update_client, realm_name, client_id, client_data}, client) do
    client
    |> put("/admin/realms/#{realm_name}/clients/#{client_id}", client_data)
    |> to_result(nil)
  end

  defp run({:users, realm_name}, client) do
    client
    |> get("/admin/realms/#{realm_name}/users")
    |> to_result(&UserRepresentation.new!/1)
  end

  defp run({:user, realm_name, user_id}, client) do
    client
    |> get("/admin/realms/#{realm_name}/users/#{user_id}")
    |> to_result(&UserRepresentation.new!/1)
  end

  defp run({:create_user, realm_name, user_data}, client) do
    client
    |> post("/admin/realms/#{realm_name}/users", user_data)
    |> to_result(nil)
  end

  defp run({:update_user, realm_name, user_id, user_data}, client) do
    client
    |> put("/admin/realms/#{realm_name}/users/#{user_id}", user_data)
    |> to_result(nil)
  end

  defp run({:delete_user, realm_name, user_id}, client) do
    client
    |> OAuth2.Client.delete("/admin/realms/#{realm_name}/users/#{user_id}")
    |> to_result(nil)
  end

  defp run({:reset_password_user, realm_name, user_id, creds}, client) do
    client
    |> put("/admin/realms/#{realm_name}/users/#{user_id}/reset-password", creds)
    |> to_result(nil)
  end

  defp run({:groups, realm_name}, client) do
    client
    |> get("/admin/realms/#{realm_name}/groups")
    |> to_result(&GroupRepresentation.new!/1)
  end

  defp run({:client_roles, realm_name, client_id}, client) do
    client
    |> get("/admin/realms/#{realm_name}/clients/#{client_id}/roles")
    |> to_result(&RoleRepresentation.new!/1)
  end

  defp run({:add_client_roles, realm_name, user_id, client_id, role}, client) do
    client
    |> post("/admin/realms/#{realm_name}/users/#{user_id}/role-mappings/clients/#{client_id}", role)
    |> to_result(nil)
  end

  #
  # OAuth2 Helpers
  #
  defp to_client(%State{} = state) do
    new_state =
      state
      |> maybe_login()
      |> maybe_refresh_token()

    if new_state.token == nil do
      Logger.error("Failed to get a token")
      {:error, "Failed to get a token"}
    else
      client =
        TokenStrategy.new(
          client_id: state.client_id,
          token: state.token,
          authorize_url: state.authorization_url,
          token_url: state.token_url
        )

      {client, new_state}
    end
  end

  defp post(client, url, body) do
    client
    |> OAuth2.Client.put_header("content-type", "application/json")
    |> OAuth2.Client.post(url, body)
  end

  defp put(client, url, body) do
    client
    |> OAuth2.Client.put_header("content-type", "application/json")
    |> OAuth2.Client.put(url, body)
  end

  defp get(client, url) do
    OAuth2.Client.get(client, url)
  end

  defp maybe_login(%{token: nil, realm: realm, client_id: client_id} = state) do
    with {:ok, well_known} <- WellknownClient.get(realm),
         {:ok, client} <-
           [realm: realm, client_id: client_id]
           |> TokenStrategy.new()
           |> OAuth2.Client.get_token(username: state.username, password: state.password) do
      %State{
        state
        | token: client.token,
          authorization_url: well_known.authorization_endpoint,
          token_url: well_known.token_endpoint
      }
    else
      {:error, error} ->
        Logger.error("Failed to login #{inspect(error)}", error: error)
        state
    end
  end

  defp maybe_login(%{token: token} = state) when is_map(token), do: state

  defp maybe_refresh_token(%{token: nil} = state), do: state

  defp maybe_refresh_token(
         %{token: token, client_id: client_id, authorization_url: authorization_url, token_url: token_url} = state
       )
       when not is_nil(token) do
    if OAuth2.AccessToken.expired?(token) do
      case [client_id: client_id, authorization_url: authorization_url, token_url: token_url, token: token]
           |> TokenStrategy.new()
           |> OAuth2.Client.refresh_token() do
        {:ok, client} ->
          %State{state | token: client.token}

        {:error, _} ->
          maybe_login(state)
      end
    else
      state
    end
  end
end
