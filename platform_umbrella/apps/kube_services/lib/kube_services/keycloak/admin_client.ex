defmodule KubeServices.Keycloak.AdminClient do
  @moduledoc false
  use GenServer
  use TypedStruct

  import CommonCore.Util.Tesla

  alias CommonCore.OpenAPI.KeycloakAdminSchema.AuthenticationExecutionInfoRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.AuthenticationFlowRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.CredentialRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.GroupRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RealmRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RequiredActionProviderRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RoleRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.UserRepresentation
  alias KubeServices.Keycloak.TokenStrategy
  alias KubeServices.Keycloak.WellknownClient
  alias OAuth2.AccessToken

  require Logger

  @type result(inner) :: {:ok, inner} | {:error, any()}

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

    field :token, AccessToken.t(), enforce: false, default: nil
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
    Logger.info("Starting KubeServices.Keycloak.AdminClient", realm: state.realm)
    {:ok, state}
  end

  #
  # Realms
  #
  @spec realms(atom | pid | {atom, any} | {:via, atom, any}) :: result(list(RealmRepresentation.t()))

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

  @spec create_realm(GenServer.server(), map()) :: result(String.t())
  @doc """
  Given a realm representation create it.
  """
  def create_realm(target \\ @me, realm) do
    GenServer.call(target, {:create_realm, realm})
  end

  #
  # Clients
  #
  @spec clients(GenServer.server(), String.t()) :: result(list(ClientRepresentation.t()))
  def clients(target \\ @me, realm_name) do
    GenServer.call(target, {:clients, realm_name})
  end

  @spec client(GenServer.server(), String.t(), String.t()) :: result(ClientRepresentation.t())
  def client(target \\ @me, realm_name, client_id) do
    GenServer.call(target, {:client, realm_name, client_id})
  end

  @spec create_client(GenServer.server(), String.t(), ClientRepresentation.t() | map()) :: result(String.t())
  def create_client(target \\ @me, realm_name, client_data) do
    GenServer.call(target, {:create_client, realm_name, client_data})
  end

  @spec update_client(GenServer.server(), String.t(), ClientRepresentation.t() | map()) :: result(String.t())
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
  @spec users(GenServer.server(), String.t()) :: result(list(UserRepresentation.t()))
  def users(target \\ @me, realm_name) do
    GenServer.call(target, {:users, realm_name})
  end

  @spec user(GenServer.server(), String.t(), String.t()) :: result(UserRepresentation.t())
  def user(target \\ @me, realm_name, user_id) do
    GenServer.call(target, {:user, realm_name, user_id})
  end

  @spec create_user(GenServer.server(), String.t(), UserRepresentation.t()) :: result(UserRepresentation.t())
  def create_user(target \\ @me, realm_name, user_data) do
    GenServer.call(target, {:create_user, realm_name, user_data})
  end

  @spec update_user(GenServer.server(), String.t(), map()) :: any
  def update_user(target \\ @me, realm_name, user_data)

  def update_user(target, realm_name, %{id: user_id} = user_data) do
    GenServer.call(target, {:update_user, realm_name, user_id, user_data})
  end

  def update_user(target, realm_name, %{"id" => user_id} = user_data) do
    GenServer.call(target, {:update_user, realm_name, user_id, user_data})
  end

  @spec delete_user(GenServer.server(), String.t(), String.t() | map()) :: any
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

  @spec reset_password_user(GenServer.server(), String.t(), String.t(), CredentialRepresentation.t() | map()) :: any
  def reset_password_user(target \\ @me, realm_name, user_id, creds) do
    GenServer.call(target, {:reset_password_user, realm_name, user_id, creds})
  end

  #
  # Groups
  #
  @spec groups(GenServer.server(), String.t()) :: result(list(GroupRepresentation.t()))
  def groups(target \\ @me, realm_name) do
    GenServer.call(target, {:groups, realm_name})
  end

  #
  # Roles
  #
  @spec roles(GenServer.server(), String.t()) :: result(list(RoleRepresentation.t()))
  def roles(target \\ @me, realm_name) do
    GenServer.call(target, {:roles, realm_name})
  end

  @spec client_roles(GenServer.server(), String.t(), String.t()) :: result(list(RoleRepresentation.t()))
  def client_roles(target \\ @me, realm_name, client_id) do
    GenServer.call(target, {:client_roles, realm_name, client_id})
  end

  @spec add_client_roles(GenServer.server(), String.t(), binary(), binary(), list()) :: result(any())
  def add_client_roles(target \\ @me, realm_name, user_id, client_id, roles_payload) do
    GenServer.call(target, {:add_client_roles, realm_name, user_id, client_id, roles_payload})
  end

  @spec add_roles(GenServer.server(), String.t(), binary(), list()) :: result(any())
  def add_roles(target \\ @me, realm_name, user_id, roles_payload) do
    GenServer.call(target, {:add_roles, realm_name, user_id, roles_payload})
  end

  #
  # Realm authentication
  #

  @spec required_actions(GenServer.server(), String.t()) :: result(list(RequiredActionProviderRepresentation.t()))
  def required_actions(target \\ @me, realm_name) do
    GenServer.call(target, {:required_actions, realm_name})
  end

  @spec required_action(GenServer.server(), String.t(), String.t()) :: result(RequiredActionProviderRepresentation.t())
  def required_action(target \\ @me, realm_name, alias) do
    GenServer.call(target, {:required_action, realm_name, alias})
  end

  @spec update_required_action(GenServer.server(), String.t(), RequiredActionProviderRepresentation.t()) :: result(atom())
  def update_required_action(target \\ @me, realm_name, action) do
    GenServer.call(target, {:update_required_action, realm_name, action})
  end

  @spec flows(GenServer.server(), String.t()) :: result(list(AuthenticationFlowRepresentation.t()))
  def flows(target \\ @me, realm_name) do
    GenServer.call(target, {:flows, realm_name})
  end

  @spec flow(GenServer.server(), String.t(), String.t()) :: result(AuthenticationFlowRepresentation.t())
  def flow(target \\ @me, realm_name, id) do
    GenServer.call(target, {:flow, realm_name, id})
  end

  @spec flow_executions(GenServer.server(), String.t(), String.t()) ::
          result(list(AuthenticationExecutionInfoRepresentation.t()))
  def flow_executions(target \\ @me, realm_name, alias) do
    GenServer.call(target, {:flow_executions, realm_name, alias})
  end

  @spec update_flow_execution(GenServer.server(), String.t(), String.t(), AuthenticationExecutionInfoRepresentation.t()) ::
          result(atom())
  def update_flow_execution(target \\ @me, realm_name, alias, execution) do
    GenServer.call(target, {:update_flow_execution, realm_name, alias, execution})
  end

  #
  # Genserver Implementation
  #

  @impl GenServer
  def handle_call(request, _from, state) do
    case to_client(state) do
      {:ok, {%{} = client, %State{} = new_state}} ->
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

  defp run({:roles, realm_name}, client) do
    client
    |> get("/admin/realms/#{realm_name}/roles")
    |> to_result(&RoleRepresentation.new!/1)
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

  defp run({:add_roles, realm_name, user_id, role}, client) do
    client
    |> post("/admin/realms/#{realm_name}/users/#{user_id}/role-mappings/realm", role)
    |> to_result(nil)
  end

  #### Realm authentication settings

  defp run({:required_actions, realm_name}, client) do
    client
    |> get("/admin/realms/#{realm_name}/authentication/required-actions")
    |> to_result(&RequiredActionProviderRepresentation.new!/1)
  end

  defp run({:required_action, realm_name, alias}, client) do
    client
    |> get("/admin/realms/#{realm_name}/authentication/required-actions/#{alias}")
    |> to_result(&RequiredActionProviderRepresentation.new!/1)
  end

  defp run({:update_required_action, realm_name, %RequiredActionProviderRepresentation{alias: alias} = action}, client) do
    client
    |> put("/admin/realms/#{realm_name}/authentication/required-actions/#{alias}", action)
    |> to_result(&RequiredActionProviderRepresentation.new!/1)
  end

  defp run({:flows, realm_name}, client) do
    client
    |> get("/admin/realms/#{realm_name}/authentication/flows")
    |> to_result(&AuthenticationFlowRepresentation.new!/1)
  end

  defp run({:flow, realm_name, id}, client) do
    client
    |> get("/admin/realms/#{realm_name}/authentication/flows/#{id}")
    |> to_result(&AuthenticationFlowRepresentation.new!/1)
  end

  defp run({:flow_executions, realm_name, alias}, client) do
    client
    |> get("/admin/realms/#{realm_name}/authentication/flows/#{alias}/executions")
    |> to_result(&AuthenticationExecutionInfoRepresentation.new!/1)
  end

  defp run({:update_flow_execution, realm_name, alias, %AuthenticationExecutionInfoRepresentation{} = execution}, client) do
    client
    |> put("/admin/realms/#{realm_name}/authentication/flows/#{alias}/executions", execution)
    |> to_result(&AuthenticationExecutionInfoRepresentation.new!/1)
  end

  #
  # OAuth2 Helpers
  #
  defp to_client(%State{} = state) do
    new_state =
      state
      |> maybe_login()
      |> maybe_refresh_token()

    cond do
      new_state.token == nil ->
        Logger.error("Failed to get a token")
        {:error, "Failed to get a token"}

      AccessToken.expired?(new_state.token) ->
        Logger.error("Token expired")
        {:error, "Token expired"}

      true ->
        client =
          TokenStrategy.new(
            client_id: new_state.client_id,
            token: new_state.token,
            authorize_url: new_state.authorization_url,
            token_url: new_state.token_url
          )

        {:ok, {client, new_state}}
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
      Logger.info("Logged in getting a token that expires at #{inspect(Map.get(client.token, :expires_at, nil))}")

      %{
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
    if AccessToken.expired?(token) do
      case [client_id: client_id, authorization_url: authorization_url, token_url: token_url, token: token]
           |> TokenStrategy.new()
           |> OAuth2.Client.refresh_token() do
        {:ok, client} ->
          Logger.debug("Refreshed token that expires at #{inspect(Map.get(client.token || %{}, :expires_at, nil))}")
          %{state | token: client.token}

        {:error, error} ->
          Logger.warning("Failed to refresh token #{inspect(error)}", error: error)
          maybe_login(%{state | token: nil})
      end
    else
      state
    end
  end
end
