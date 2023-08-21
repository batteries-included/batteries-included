defmodule CommonCore.Keycloak.AdminClient do
  @moduledoc """
  This GenServer is a single entry point into
  the Keycloak api. It handles open id connect
  token rotation.

  The following apis are currently implemented:

  ## Realms

  List the realms on the keycloak instance

  ## Clients

  List all the clients that can connect to a given realm.

  ## Users

  List all the users that can login to a given realm

  ## Get User

  Get a single user

  ## Delete User

  Delete a single user

  ## Refresh

  Force a refresh of the access token

  ## Login

  Force a username/password login.

  """
  use GenServer
  use TypedStruct

  alias CommonCore.OpenApi.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.Keycloak.TokenAcquirer
  alias CommonCore.Keycloak.TeslaBuilder
  alias CommonCore.OpenApi.KeycloakAdminSchema

  require Logger

  @state_opts ~w(username password base_url adapter)a

  @me __MODULE__

  typedstruct module: State do
    # This is the adapter to use for Tesla, a way to pass in a
    # different module (for example a mocked module) if you wanted.
    field :adapter, module(), enforce: false

    field :username, String.t()
    field :password, String.t()
    field :base_url, String.t()

    field :access_token, String.t(), enforce: false
    field :access_expire, Time.t(), enforce: false

    field :refresh_token, String.t(), enforce: false
    field :refresh_expire, Time.t(), enforce: false

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

  def reset(target \\ @me, base_url, username, password) do
    GenServer.call(target, {:reset, base_url: base_url, username: username, password: password})
  end

  def login(target \\ @me) do
    GenServer.call(target, :login)
  end

  def refresh(target \\ @me) do
    GenServer.call(target, :refresh)
  end

  def realms(target \\ @me) do
    GenServer.call(target, :realms)
  end

  def realm(target \\ @me, name) do
    GenServer.call(target, {:realm, name})
  end

  def create_realm(target \\ @me, realm) do
    GenServer.call(target, {:create_realm, realm})
  end

  @spec clients(atom | pid | {atom, any} | {:via, atom, any}, String.t()) ::
          {:ok, list(ClientRepresentation.t())} | {:error, any()}
  def clients(target \\ @me, realm_name) do
    GenServer.call(target, {:clients, realm_name})
  end

  def users(target \\ @me, realm_name) do
    GenServer.call(target, {:users, realm_name})
  end

  def user(target \\ @me, realm_name, user_id) do
    GenServer.call(target, {:user, realm_name, user_id})
  end

  def delete_user(target \\ @me, realm_name, user_id) do
    GenServer.call(target, {:delete_user, realm_name, user_id})
  end

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

  def handle_call(:realms, _from, %State{} = state) do
    case handle_auth(state) do
      {:ok, %State{} = new_state} -> {:reply, do_list_realms(new_state), new_state}
      error -> {:reply, error, reset_tokens(state)}
    end
  end

  def handle_call({:realm, realm_name}, _from, %State{} = state) do
    case handle_auth(state) do
      {:ok, %State{} = new_state} -> {:reply, do_get_realm(realm_name, new_state), new_state}
      error -> {:reply, error, reset_tokens(state)}
    end
  end

  def handle_call({:create_realm, realm}, _from, %State{} = state) do
    case handle_auth(state) do
      {:ok, %State{} = new_state} -> {:reply, do_create_realm(realm, new_state), new_state}
      error -> {:reply, error, reset_tokens(state)}
    end
  end

  def handle_call({:clients, realm_name}, _from, %State{} = state) do
    case handle_auth(state) do
      {:ok, %State{} = new_state} -> {:reply, do_list_clients(realm_name, new_state), new_state}
      error -> {:reply, error, reset_tokens(state)}
    end
  end

  def handle_call({:users, realm_name}, _from, %State{} = state) do
    case handle_auth(state) do
      {:ok, %State{} = new_state} -> {:reply, do_list_users(realm_name, new_state), new_state}
      error -> {:reply, error, reset_tokens(state)}
    end
  end

  def handle_call({:user, realm_name, user_id}, _from, %State{} = state) do
    case handle_auth(state) do
      {:ok, %State{} = new_state} ->
        {:reply, do_get_user(realm_name, user_id, new_state), new_state}

      error ->
        {:reply, error, reset_tokens(state)}
    end
  end

  def handle_call({:delete_user, realm_name, user_id}, _from, %State{} = state) do
    case handle_auth(state) do
      {:ok, %State{} = new_state} ->
        {:reply, do_delete_user(realm_name, user_id, new_state), new_state}

      error ->
        {:reply, error, reset_tokens(state)}
    end
  end

  def handle_call(
        {:reset, opts},
        _from,
        %State{base_url: base_url, username: username, password: password} = state
      ) do
    new_base_url = Keyword.get(opts, :base_url, base_url)
    new_username = Keyword.get(opts, :username, username)
    new_password = Keyword.get(opts, :password, password)

    if new_base_url != base_url || new_username != username || new_password != password do
      Logger.debug("Resetting credentials or base url for keycloak")

      new_state =
        state
        |> reset_http_params(new_username, new_password, new_base_url)
        |> reset_tokens()
        |> build_base_client()

      {:reply, :ok, new_state}
    else
      {:reply, :ok, state}
    end
  end

  @spec reset_http_params(State.t(), String.t(), String.t(), String.t()) :: State.t()
  defp reset_http_params(state, username, password, base_url) do
    %State{state | username: username, password: password, base_url: base_url}
  end

  @spec reset_tokens(State.t()) :: State.t()
  defp reset_tokens(state) do
    %State{
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

      _ ->
        {:error, :unknown_error}
    end
  end

  # If there's no good refresh token then we need to login
  @spec maybe_aquire_refresh(State.t()) :: {:ok, State.t()} | {:error, any()}
  defp maybe_aquire_refresh(%State{refresh_token: tok, refresh_expire: expire} = state) do
    cond do
      tok == nil -> do_login(state)
      1 == Timex.compare(Timex.now(), expire) -> do_login(state)
      true -> {:ok, state}
    end
  end

  # If there's no good access token, but there is a refresh token
  # Then use the refresh token.
  @spec maybe_aquire_access(State.t()) :: {:ok, State.t()} | {:error, any()}
  defp maybe_aquire_access(%State{access_expire: expire} = state) do
    if 1 == Timex.compare(Timex.now(), expire) do
      do_refresh(state)
    else
      {:ok, state}
    end
  end

  @spec build_bearer_client(State.t() | {:error, any()} | any()) :: State.t() | {:error, any()}
  def build_bearer_client(
        %State{access_token: token, base_url: base_url, adapter: adapter} = state
      ) do
    %State{state | bearer_client: TeslaBuilder.build_client(base_url, token, adapter)}
  end

  def build_bearer_client({:error, err}), do: {:error, err}

  def build_base_client(%State{base_url: base_url, adapter: adapter} = state) do
    %State{state | base_client: TeslaBuilder.build_client(base_url, nil, adapter)}
  end

  @spec update_token(TokenAcquirer.TokenResult.t(), State.t()) :: State.t()
  defp update_token(%TokenAcquirer.TokenResult{} = token_result, state) do
    build_bearer_client(%State{
      state
      | access_token: token_result.access_token,
        refresh_token: token_result.refresh_token,
        access_expire: token_result.expires,
        refresh_expire: token_result.refresh_expires
    })
  end

  @spec do_login(State.t() | {:error, any()}) :: {:ok, State.t()} | {:error, any()}
  defp do_login(%State{base_client: client, username: username, password: password} = state) do
    case TokenAcquirer.login(client, username, password) do
      {:ok, token_result} -> {:ok, update_token(token_result, state)}
      {:error, err} -> {:error, err}
    end
  end

  @spec do_refresh(State.t()) :: {:ok, State.t()} | {:error, any()}
  defp do_refresh(%State{base_client: client, refresh_token: refresh_token} = state) do
    case TokenAcquirer.refresh(client, refresh_token) do
      {:ok, token_result} -> {:ok, update_token(token_result, state)}
      {:error, err} -> {:error, err}
    end
  end

  defp do_list_realms(%State{bearer_client: client} = _state) do
    client
    |> Tesla.get("/admin/realms")
    |> to_result(&KeycloakAdminSchema.RealmRepresentation.new!/1)
  end

  defp do_get_realm(realm_name, %State{bearer_client: client} = _state) do
    client
    |> Tesla.get("/admin/realms/" <> realm_name)
    |> to_result(&KeycloakAdminSchema.RealmRepresentation.new!/1)
  end

  defp do_create_realm(realm, %State{bearer_client: client} = _state) do
    client
    |> Tesla.post("/admin/realms", realm)
    |> to_result(nil)
  end

  defp do_list_clients(realm_name, %State{bearer_client: client} = _state) do
    client
    |> Tesla.get("/admin/realms/" <> realm_name <> "/clients")
    |> to_result(&KeycloakAdminSchema.ClientRepresentation.new!/1)
  end

  defp do_list_users(realm_name, %State{bearer_client: client} = _state) do
    client
    |> Tesla.get("/admin/realms/" <> realm_name <> "/users")
    |> to_result(&KeycloakAdminSchema.UserRepresentation.new!/1)
  end

  defp do_get_user(realm_name, user_id, %State{bearer_client: client} = _state) do
    client
    |> Tesla.get("/admin/realms/" <> realm_name <> "/users/" <> user_id)
    |> to_result(&KeycloakAdminSchema.UserRepresentation.new!/1)
  end

  defp do_delete_user(realm_name, user_id, %State{bearer_client: client} = _state) do
    client
    |> Tesla.delete("/admin/realms/" <> realm_name <> "/users/" <> user_id)
    |> to_result()
  end

  defp to_result({:ok, %{status: 200, body: _body}} = in_res), do: to_result(in_res, nil)

  defp to_result({:ok, %{status: 200, body: body}}, mapper) when is_list(body) do
    {:ok, Enum.map(body, mapper)}
  end

  defp to_result({:ok, %{status: 200, body: body}}, nil) do
    {:ok, body}
  end

  defp to_result({:ok, %{status: 200, body: body}}, mapper) do
    {:ok, mapper.(body)}
  end

  defp to_result({:ok, %{status: 201, headers: headers}}, nil) do
    location =
      headers
      |> Enum.filter(fn {key, _} -> key == "location" end)
      |> Enum.map(fn {_, value} -> value end)
      |> List.first()

    {:ok, location}
  end

  defp to_result({:ok, %{body: %{"error" => error}}}, _mapper) do
    {:error, error}
  end

  defp to_result({:error, error}, _mapper), do: {:error, error}

  defp to_result(_error, _mapper) do
    {:error, :unknown_keycloak_error}
  end
end
