defmodule CommonCore.Keycloak.AdminClient do
  @moduledoc """
  This GenServer is a single entry point into
  the Keycloak api. It handles open id connect
  token rotation.

  See rest documentation here:
  https://www.keycloak.org/docs-api/22.0.1/rest-api/index.html

  The following apis are currently implemented:

  ## Realms

  - List the realms on the keycloak instance
  - Get a single realm
  - Create a new realm

  ## Clients

  - List all the clients that can connect to a given realm.
  - Get a single client
  - Create / Update a client

  ## Users

  - List all the users that can login to a given realm
  - Get a single user
  - Create / Delete a single user
  - Reset a single user's password

  ## Groups

  - List all groups for a realm

  ## REST Auth

  - Force a username/password login.
  - Force a refresh of the access token

  """
  use GenServer
  use TypedStruct

  import CommonCore.Util.Tesla

  alias CommonCore.Keycloak.TeslaBuilder
  alias CommonCore.Keycloak.TokenAcquirer
  alias CommonCore.OpenAPI.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.CredentialRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.GroupRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RealmRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RoleRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.UserRepresentation

  require Logger

  @type keycloak_url :: binary()
  @type result(inner) :: {:ok, inner} | {:error, any()}

  @state_opts ~w(username password base_url adapter)a

  @me __MODULE__

  @base_path "/admin/realms/"

  typedstruct module: State do
    # This is the adapter to use for Tesla, a way to pass in a
    # different module (for example a mocked module) if you wanted.
    field :adapter, module(), enforce: false

    field :username, String.t()
    field :password, String.t()
    field :base_url, String.t()

    field :access_token, String.t(), enforce: false
    field :access_expire, DateTime.t(), enforce: false

    field :refresh_token, String.t(), enforce: false
    field :refresh_expire, DateTime.t(), enforce: false

    field :bearer_client, Tesla.Client.t(), enforce: false
    field :base_client, Tesla.Client.t(), enforce: false
  end

  def start_link(opts \\ []) do
    {state_opts, server_opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, server_opts)
  end

  def init(args) do
    state =
      State
      |> struct(args)
      |> build_base_client()

    {:ok, state}
  end

  @doc """
  Login to the Keycloak
  """
  def login(target \\ @me) do
    GenServer.call(target, :login)
  end

  @doc """
  Refresh the access tokens using configured credentials
  """
  def refresh(target \\ @me) do
    GenServer.call(target, :refresh)
  end

  @spec realms(GenServer.server()) :: result(list(RealmRepresentation.t()))
  @doc """
  List the realms on Keycloak

  This is a rest call into the api server.
  """
  def realms(target \\ @me) do
    GenServer.call(target, {:realms})
  end

  @spec realm(GenServer.server(), any) :: result(RealmRepresentation.t())
  @doc """
  Get the realm representation from Keycloak

  This is a rest call into the api server.
  """
  def realm(target \\ @me, name) do
    GenServer.call(target, {:realm, name})
  end

  @spec create_realm(GenServer.server(), map()) :: result(keycloak_url())
  @doc """
  Given a realm representation create it.

  This is a rest call into keycloak
  """
  def create_realm(target \\ @me, realm) do
    GenServer.call(target, {:create_realm, realm})
  end

  @spec clients(GenServer.server(), String.t()) :: result(list(ClientRepresentation.t()))
  def clients(target \\ @me, realm_name) do
    GenServer.call(target, {:clients, realm_name})
  end

  @spec client(GenServer.server(), String.t(), String.t()) :: result(ClientRepresentation.t())
  def client(target \\ @me, realm_name, client_id) do
    GenServer.call(target, {:client, realm_name, client_id})
  end

  @spec delete_client(GenServer.server(), String.t(), String.t()) :: result(any())
  def delete_client(target \\ @me, realm_name, client_id) do
    GenServer.call(target, {:delete_client, realm_name, client_id})
  end

  @spec create_client(GenServer.server(), String.t(), ClientRepresentation.t()) :: result(keycloak_url())
  def create_client(target \\ @me, realm_name, client_data) do
    GenServer.call(target, {:create_client, realm_name, client_data})
  end

  @spec update_client(GenServer.server(), String.t(), ClientRepresentation.t() | map()) :: result(keycloak_url())
  def update_client(target \\ @me, realm_name, client_data)

  def update_client(target, realm_name, %{id: id} = client_data) do
    GenServer.call(target, {:update_client, realm_name, id, client_data})
  end

  def update_client(target, realm_name, %{"id" => id} = client_data) do
    GenServer.call(target, {:update_client, realm_name, id, client_data})
  end

  @spec users(GenServer.server(), String.t()) :: result(list(UserRepresentation.t()))
  def users(target \\ @me, realm_name) do
    GenServer.call(target, {:users, realm_name})
  end

  @spec user(GenServer.server(), String.t(), String.t()) :: result(UserRepresentation.t())
  def user(target \\ @me, realm_name, user_id) do
    GenServer.call(target, {:user, realm_name, user_id})
  end

  @spec delete_user(GenServer.server(), String.t(), String.t()) :: result(any)
  def delete_user(target \\ @me, realm_name, user_id) do
    GenServer.call(target, {:delete_user, realm_name, user_id})
  end

  @spec create_user(GenServer.server(), String.t(), UserRepresentation.t()) :: result(UserRepresentation.t())
  def create_user(target \\ @me, realm_name, user_data) do
    GenServer.call(target, {:create_user, realm_name, user_data})
  end

  @spec groups(GenServer.server(), String.t()) :: result(list(GroupRepresentation.t()))
  def groups(target \\ @me, realm_name) do
    GenServer.call(target, {:groups, realm_name})
  end

  @spec roles(GenServer.server(), String.t()) :: result(list(RoleRepresentation.t()))
  def roles(target \\ @me, realm_name) do
    GenServer.call(target, {:roles, realm_name})
  end

  @spec client_roles(GenServer.server(), String.t(), binary()) :: result(list(ClientRepresentation.t()))
  def client_roles(target \\ @me, realm_name, client_id) do
    GenServer.call(target, {:client_roles, realm_name, client_id})
  end

  @spec add_client_roles(GenServer.server(), String.t(), binary(), binary(), list()) :: result(any())
  def add_client_roles(target \\ @me, realm_name, user_id, client_id, roles_payload) do
    GenServer.call(target, {:add_client_roles, realm_name, user_id, client_id, roles_payload})
  end

  @spec reset_password_user(GenServer.server(), String.t(), String.t(), CredentialRepresentation.t()) :: result(any)
  def reset_password_user(target \\ @me, realm_name, user_id, creds) do
    GenServer.call(target, {:reset_password_user, realm_name, user_id, creds})
  end

  ### Handles

  def handle_call(:refresh, _from, state) do
    with {:ok, %State{} = with_refresh} <- maybe_aquire_refresh(state),
         {:ok, %State{} = refreshed_state} <- do_refresh(with_refresh) do
      {:reply, :ok, refreshed_state}
    else
      error -> {:reply, error, reset_tokens(state)}
    end
  end

  def handle_call(:login, _from, state) do
    case do_login(state) do
      {:ok, new_state} -> {:reply, :ok, new_state}
      error -> {:reply, error, reset_tokens(state)}
    end
  end

  # catchall that wraps the request with_auth()
  def handle_call(request, _from, %State{} = state), do: with_auth(state, &run(request, &1.bearer_client))

  defp run({:realms}, client) do
    client
    |> Tesla.get(@base_path)
    |> to_result(&RealmRepresentation.new!/1)
  end

  defp run({:realm, realm_name}, client) do
    client
    |> Tesla.get(@base_path <> realm_name)
    |> to_result(&RealmRepresentation.new!/1)
  end

  defp run({:create_realm, realm}, client) do
    client
    |> Tesla.post(@base_path, realm)
    |> to_result(nil)
  end

  #
  # Clients http methods
  #

  defp run({:clients, realm_name}, client) do
    client
    |> Tesla.get(@base_path <> realm_name <> "/clients")
    |> to_result(&ClientRepresentation.new!/1)
  end

  defp run({:client, realm_name, client_id}, client) do
    client
    |> Tesla.get(@base_path <> realm_name <> "/clients/" <> client_id)
    |> to_result(&ClientRepresentation.new!/1)
  end

  defp run({:create_client, realm_name, client_data}, client) do
    client
    |> Tesla.post(@base_path <> realm_name <> "/clients", client_data)
    |> to_result(nil)
  end

  defp run({:update_client, realm_name, id, client_data}, client) do
    client
    |> Tesla.put(@base_path <> realm_name <> "/clients/" <> id, client_data)
    |> to_result(nil)
  end

  #
  # Users http methods
  #

  defp run({:users, realm_name}, client) do
    client
    |> Tesla.get(@base_path <> realm_name <> "/users")
    |> to_result(&UserRepresentation.new!/1)
  end

  defp run({:user, realm_name, user_id}, client) do
    client
    |> Tesla.get(@base_path <> realm_name <> "/users/" <> user_id)
    |> to_result(&UserRepresentation.new!/1)
  end

  defp run({:delete_user, realm_name, user_id}, client) do
    client
    |> Tesla.delete(@base_path <> realm_name <> "/users/" <> user_id)
    |> to_result(nil)
  end

  defp run({:create_user, realm_name, user_data}, client) do
    client
    |> Tesla.post(@base_path <> realm_name <> "/users", user_data)
    |> to_result(nil)
  end

  defp run({:reset_password_user, realm_name, user_id, creds}, client) do
    client
    |> Tesla.put(@base_path <> realm_name <> "/users/" <> user_id <> "/reset-password", creds)
    |> to_result(nil)
  end

  #
  # Groups http methods
  #
  defp run({:groups, realm_name}, client) do
    client
    |> Tesla.get(@base_path <> realm_name <> "/groups")
    |> to_result(&GroupRepresentation.new!/1)
  end

  #
  # roles http methods
  #
  defp run({:roles, realm_name}, client) do
    client
    |> Tesla.get(@base_path <> realm_name <> "/roles")
    |> to_result(&RoleRepresentation.new!/1)
  end

  defp run({:client_roles, realm_name, client_id}, client) do
    client
    |> Tesla.get(@base_path <> realm_name <> "/clients/" <> client_id <> "/roles")
    |> to_result(&RoleRepresentation.new!/1)
  end

  defp run({:add_client_roles, realm_name, user_id, client_id, role}, client) do
    client
    |> Tesla.post(@base_path <> realm_name <> "/users/" <> user_id <> "/role-mappings/clients/" <> client_id, role)
    |> to_result(nil)
  end

  #### Helpers
  defp with_auth(state, fun) do
    case handle_auth(state) do
      {:ok, %State{} = new_state} ->
        {:reply, fun.(new_state), new_state}

      error ->
        {:reply, error, reset_tokens(state)}
    end
  end

  @spec reset_tokens(State.t()) :: State.t()
  defp reset_tokens(state) do
    %{
      state
      | refresh_token: nil,
        refresh_expire: nil,
        access_token: nil,
        access_expire: nil,
        bearer_client: nil
    }
  end

  defp handle_auth(%State{} = state) do
    # This with is a bit much I admit.
    #
    # However it's here for a a good reason:
    # error cases with http and refreshing
    # short time tokens are complex.
    #
    # Likely we won't need to get new tokens for either
    # refresh or access. maybe_aquire_refresh
    # and maybe_aquire_access will short circuit
    # returning ok if we have every reason to
    # think the tokens are valid
    #
    # But if we do need to get those tokens
    # Then it's very possible that the http/rpc call
    # could fail.
    #
    # Those errors need to be handleded differently
    # if they were the result of an explcit `&login/0` call
    # or if they were there before sending a different call.
    #
    # To that end this with will try and differentiate where errors are coming from.
    with {:ensure_refresh_valid, {:ok, with_refresh}} <-
           {:ensure_refresh_valid, maybe_aquire_refresh(state)},
         {:ensure_access_valid, {:ok, with_access}} <-
           {:ensure_access_valid, maybe_aquire_access(with_refresh)} do
      {:ok, with_access}
    else
      {:ensure_refresh_valid, {:error, error}} ->
        Logger.warning("Failed to get valid refresh token, error #{inspect(error)}")
        {:error, error}

      {:ensure_access_valid, {:error, error}} ->
        Logger.warning("Failed to get valid access token, error #{inspect(error)}")
        {:error, error}
    end
  end

  # If there's no good refresh token then we need to login
  @spec maybe_aquire_refresh(State.t()) :: result(State.t())
  defp maybe_aquire_refresh(%State{refresh_token: tok, refresh_expire: expire} = state) do
    cond do
      tok == nil -> do_login(state)
      :gt == DateTime.compare(DateTime.utc_now(), expire) -> do_login(state)
      true -> {:ok, state}
    end
  end

  # If there's no good access token, but there is a refresh token
  # Then use the refresh token.
  @spec maybe_aquire_access(State.t()) :: result(State.t())
  defp maybe_aquire_access(%State{access_expire: nil} = state) do
    do_refresh(state)
  end

  defp maybe_aquire_access(%State{access_expire: expire} = state) do
    if :gt == DateTime.compare(DateTime.utc_now(), expire) do
      do_refresh(state)
    else
      {:ok, state}
    end
  end

  defp build_bearer_client(%State{access_token: token, base_url: base_url, adapter: adapter} = state) do
    %{state | bearer_client: TeslaBuilder.build_client(base_url, token, adapter)}
  end

  defp build_base_client(%State{base_url: base_url, adapter: adapter} = state) do
    %{state | base_client: TeslaBuilder.build_client(base_url, nil, adapter)}
  end

  @spec update_token(TokenAcquirer.TokenResult.t(), State.t()) :: State.t()
  defp update_token(%TokenAcquirer.TokenResult{} = token_result, state) do
    build_bearer_client(%{
      state
      | access_token: token_result.access_token,
        refresh_token: token_result.refresh_token,
        access_expire: token_result.expires,
        refresh_expire: token_result.refresh_expires
    })
  end

  @spec do_login(State.t() | {:error, any()}) :: result(State.t())
  defp do_login(%State{base_client: client, username: username, password: password} = state) do
    case TokenAcquirer.login(client, username, password) do
      {:ok, token_result} -> {:ok, update_token(token_result, state)}
      {:error, err} -> {:error, err}
    end
  end

  @spec do_refresh(State.t()) :: result(State.t())
  defp do_refresh(%State{base_client: client, refresh_token: refresh_token} = state) do
    case TokenAcquirer.refresh(client, refresh_token) do
      {:ok, token_result} -> {:ok, update_token(token_result, state)}
      {:error, err} -> {:error, err}
    end
  end
end
