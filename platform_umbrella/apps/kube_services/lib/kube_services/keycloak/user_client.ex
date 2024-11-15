defmodule KubeServices.Keycloak.UserClient do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias KubeServices.Keycloak.TokenStrategy

  require Logger

  @state_opts ~w(realm client_id client_secret battery_core_url)a
  @me __MODULE__

  typedstruct module: State do
    field :realm, String.t(), default: "batterycore"
    field :client_id, String.t(), default: "batterycore"
    field :client_secret, String.t(), default: nil

    field :battery_core_url, String.t(), default: nil
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
    Logger.info("Starting KubeServices.Keycloak.UserClient", realm: state.realm)
    {:ok, state}
  end

  @impl GenServer
  def handle_call(
        {:authorize_url, opts},
        _from,
        %State{realm: realm, client_id: client_id, client_secret: client_secret, battery_core_url: battery_core_url} =
          state
      ) do
    {%OAuth2.Client{} = _new_client, url} =
      [realm: realm, client_id: client_id, client_secret: client_secret]
      |> TokenStrategy.new()
      |> OAuth2.Client.authorize_url(Keyword.put_new(opts, :battery_core_url, battery_core_url))

    {:reply, {:ok, url}, state}
  end

  def handle_call(
        {:get_token, params},
        _from,
        %State{realm: realm, client_id: client_id, client_secret: client_secret} = state
      ) do
    case [realm: realm, client_id: client_id, client_secret: client_secret]
         |> TokenStrategy.new()
         |> OAuth2.Client.get_token(params) do
      {:ok, client} -> {:reply, {:ok, client.token}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call(
        {:refresh_token, token},
        _from,
        %State{realm: realm, client_id: client_id, client_secret: client_secret} = state
      ) do
    case [realm: realm, client_id: client_id, client_secret: client_secret, token: token]
         |> TokenStrategy.new()
         |> OAuth2.Client.refresh_token() do
      {:ok, client} -> {:reply, {:ok, client.token}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call(
        {:userinfo, token},
        _from,
        %State{realm: realm, client_id: client_id, client_secret: client_secret} = state
      ) do
    client =
      [realm: realm, client_id: client_id, client_secret: client_secret, token: token]
      |> TokenStrategy.new()
      |> OAuth2.Client.put_header("content-type", "application/json")

    path = "/realms/#{realm}/protocol/openid-connect/userinfo"

    case OAuth2.Client.get(client, path) do
      {:ok, result} -> {:reply, {:ok, result.body}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def authorize_url(target \\ @me, opts \\ []) do
    GenServer.call(target, {:authorize_url, opts})
  end

  def get_token(target \\ @me, params) do
    GenServer.call(target, {:get_token, params})
  end

  def refresh_token(target \\ @me, token) do
    GenServer.call(target, {:refresh_token, token})
  end

  def userinfo(target \\ @me, token) do
    GenServer.call(target, {:userinfo, token})
  end
end
