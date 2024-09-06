defmodule KubeServices.Keycloak.TokenStrategy do
  @moduledoc false
  use OAuth2.Strategy

  alias CommonCore.StateSummary.URLs
  alias KubeServices.Keycloak.WellknownClient
  alias KubeServices.SystemState.Summarizer

  def new(params \\ []) do
    client_id =
      Keyword.get_lazy(params, :client_id, fn ->
        # TODO: Get the client_id from control servers's created client
        "admin-cli"
      end)

    client_secret = Keyword.get(params, :client_secret, "")

    param_authorize_url = Keyword.get(params, :authorize_url, nil)
    param_token_url = Keyword.get(params, :token_url, nil)

    {authorize_url, token_url} =
      if !param_authorize_url || !param_token_url do
        realm = Keyword.get(params, :realm, "master")
        {:ok, well_known} = WellknownClient.get(realm)
        {well_known.authorization_endpoint, well_known.token_endpoint}
      else
        {param_authorize_url, param_token_url}
      end

    url = URI.parse(token_url)

    [
      authorize_url: authorize_url,
      token_url: token_url,
      client_id: client_id,
      client_secret: client_secret,
      site: "#{url.scheme}://#{url.authority}",
      token: Keyword.get(params, :token, nil),
      token_method: :post
    ]
    |> Keyword.put(:strategy, __MODULE__)
    |> OAuth2.Client.new()
    |> put_serializer("application/json", Jason)
  end

  @doc """
  Not used for this strategy.
  """
  @impl OAuth2.Strategy
  def authorize_url(client, params) do
    client
    |> put_param(:response_type, "code")
    |> put_param(:redirect_uri, redirect_uri(params))
    |> put_param(:client_id, client.client_id)
  end

  @doc """
  Refresh an access token given the specified validation code.
  """
  @impl OAuth2.Strategy
  def get_token(client, params, headers) do
    refresh_token = maybe_get_refresh_token(client, params)
    code = maybe_get_code(client, params)
    {username, password} = maybe_get_username_password(client, params)

    cond do
      refresh_token ->
        token_via_refresh(client, refresh_token, headers)

      code ->
        token_via_code(client, code, redirect_uri(params), headers)

      password && username ->
        token_via_password(client, username, password, headers)

      true ->
        raise OAuth2.Error,
          reason: "Missing required key `refresh_token` or `code` or `username` and `password` for #{inspect(__MODULE__)}"
    end
  end

  def redirect_uri(params) do
    return_to = Keyword.get(params, :return_to, nil)
    battery_core_url = maybe_get_battery_core_url(params)

    control_server_url = get_control_server_url(return_to, battery_core_url)

    uri = control_server_url |> URI.parse() |> URI.append_path("/sso/callback")

    if return_to do
      uri
      |> URI.append_query(URI.encode_query(%{"return_to" => return_to}))
      |> URI.to_string()
    else
      URI.to_string(uri)
    end
  end

  defp get_control_server_url(return_to, battery_core_url)

  # if return_to isn't set or is relative, use battery_core_url
  defp get_control_server_url(nil, battery_core_url), do: battery_core_url
  defp get_control_server_url("/" <> _return_to, battery_core_url), do: battery_core_url

  # or parse return_to
  defp get_control_server_url(return_to, _battery_core_url) do
    return_uri = URI.parse(return_to)
    "#{return_uri.scheme}://#{return_uri.authority}"
  end

  defp maybe_get_battery_core_url(params) do
    Keyword.get_lazy(params, :battery_core_url, fn ->
      Summarizer.cached() |> URLs.uri_for_battery(:battery_core) |> URI.to_string()
    end)
  end

  defp maybe_get_refresh_token(client, params) do
    Keyword.get_lazy(params, :refresh_token, fn -> Map.get(client.token || %{}, :refresh_token) end)
  end

  defp maybe_get_code(client, params) do
    Keyword.get_lazy(params, :code, fn -> Map.get(client.token || %{}, :code) end)
  end

  defp maybe_get_username_password(client, params) do
    username = Keyword.get_lazy(params, :username, fn -> Map.get(client.params || %{}, "username") end)
    password = Keyword.get_lazy(params, :password, fn -> Map.get(client.params || %{}, "password") end)
    {username, password}
  end

  defp token_via_refresh(client, refresh_token, headers) do
    client
    |> put_param(:refresh_token, refresh_token)
    |> put_param(:grant_type, "refresh_token")
    |> basic_auth()
    |> put_headers(headers)
  end

  defp token_via_code(client, code, redirect_uri, headers) do
    client
    |> put_param(:code, code)
    |> put_param(:grant_type, "authorization_code")
    |> put_param(:redirect_uri, redirect_uri)
    |> put_param(:client_id, client.client_id)
    |> basic_auth()
    |> put_headers(headers)
  end

  defp token_via_password(client, username, password, headers) do
    client
    |> put_param(:username, username)
    |> put_param(:password, password)
    |> put_param(:grant_type, "password")
    |> put_param(:client_id, client.client_id)
    |> put_header("accept", "application/json")
    |> put_headers(headers)
  end
end
