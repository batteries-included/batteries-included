defmodule CommonCore.Keycloak.TokenAcquirer do
  @moduledoc """
  This module will aquire a new openid connect
  token from keycloak. Either via username/password
  or a refresh token.

  It requires a Tesla
  """

  # We have to masqerade as the admin cli because
  # it's there before any other configuration.
  @client_id "admin-cli"
  @password_grant_type "password"
  @refresh_grant_type "refresh_token"

  @master_realm_login_url "/realms/master/protocol/openid-connect/token"

  use TypedStruct

  require Logger

  typedstruct module: TokenResult do
    field :access_token, String.t()
    field :expires, DateTime.t()
    field :refresh_token, String.t()
    field :refresh_expires, DateTime.t()
  end

  @spec refresh(Tesla.Client.t(), String.t(), keyword) ::
          {:error, any} | {:ok, CommonCore.Keycloak.TokenAcquirer.TokenResult.t()}
  def refresh(client, token, opts \\ [client_id: @client_id]) do
    # Take the start time just before sending the request
    # This ensures that we'll never overestimate the expire times.
    start_time = Timex.now()

    body =
      opts
      |> Keyword.merge(
        refresh_token: token,
        grant_type: @refresh_grant_type
      )
      |> Map.new()

    client
    |> Tesla.post(@master_realm_login_url, body)
    |> extract_body(start_time)
  end

  @spec login(Tesla.Client.t(), String.t(), String.t(), keyword) ::
          {:error, any} | {:ok, CommonCore.Keycloak.TokenAcquirer.TokenResult.t()}
  def login(client, username, password, opts \\ [client_id: @client_id]) do
    # Take the start time just before sending the request
    # This ensures that we'll never overestimate the expire times.
    start_time = Timex.now()

    body =
      opts
      |> Keyword.merge(
        username: username,
        password: password,
        grant_type: @password_grant_type
      )
      |> Map.new()

    client
    |> Tesla.post(@master_realm_login_url, body)
    |> extract_body(start_time)
  end

  # Given a result from `&Tesla.post/3` extract the successful json decoding of
  # of the http result.
  #
  # This assumes then that the tesla client we're using is configured with the JSON middleware
  # and the base url middleware.
  @spec extract_body({:ok, map()} | {:error, any()}, DateTime.t()) ::
          {:ok, TokenResult.t()} | {:error, any()}
  defp extract_body({:ok, %{status: 200, body: body}}, start_time) do
    # Try to un-wrap the map from the client.
    # It should have these fields.
    # We don't need to do too much with the tokens
    # currently
    case body do
      %{
        "access_token" => access_token,
        "expires_in" => expires_in,
        "refresh_expires_in" => refresh_expires_in,
        "refresh_token" => refresh_token
      } ->
        {:ok,
         %TokenResult{
           access_token: access_token,
           expires: Timex.shift(start_time, seconds: expires_in),
           refresh_token: refresh_token,
           refresh_expires: Timex.shift(start_time, seconds: refresh_expires_in)
         }}

      _ ->
        # If we got a 200 result map, but it's not structured the
        # was we expected it then return the error the
        # then end user.
        keys = Map.keys(body)
        Logger.debug("Unable to decode token payload result. Keys: #{Enum.join(keys, ", ")}")
        {:error, :unable_decode_token}
    end
  end

  defp extract_body({:error, err}, _), do: {:error, err}
  defp extract_body(err, _), do: {:error, err}
end
