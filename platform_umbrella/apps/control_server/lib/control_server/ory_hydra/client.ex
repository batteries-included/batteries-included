defmodule ControlServer.OryHydraClient do
  alias Finch.Response

  require Logger

  @finch_client ControlServer.OryHydraFinch

  @base_get_login_request "/oauth2/auth/requests/login"
  @base_approve_login "/oauth2/auth/requests/login/accept"
  @base_reject_login "/oauth2/auth/requests/login/reject"

  @default_host "localhost"
  @default_port 4445
  @default_scheme "http"

  def get_login_request(login_challenge, opts \\ []) do
    :get
    |> Finch.build(get_login_uri(login_challenge, opts))
    |> Finch.request(@finch_client)
    |> handle_parent_response()
  end

  def approve_login(login_challenge, subject, opts \\ []) do
    :put
    |> Finch.build(approve_login_uri(login_challenge, opts), [], approve_login_body(subject))
    |> Finch.request(@finch_client)
    |> handle_parent_response()
  end

  def reject_login(login_challenge, opts \\ []) do
    :put
    |> Finch.build(reject_login_uri(login_challenge, opts))
    |> Finch.request(@finch_client)
    |> handle_parent_response()
  end

  defp get_login_uri(login_challenge, opts) do
    @base_get_login_request
    |> URI.parse()
    |> default_uri(opts)
    |> Map.put(:query, URI.encode_query(login_challenge: login_challenge))
  end

  defp approve_login_uri(login_challenge, opts) do
    @base_approve_login
    |> URI.parse()
    |> default_uri(opts)
    |> Map.put(:query, URI.encode_query(login_challenge: login_challenge))
  end

  defp approve_login_body(subject) do
    Jason.encode!(%{subject: subject})
  end

  defp reject_login_uri(login_challenge, opts) do
    @base_reject_login
    |> URI.parse()
    |> default_uri(opts)
    |> Map.put(:query, URI.encode_query(login_challenge: login_challenge))
  end

  defp default_uri(uri, opts) do
    uri
    |> Map.put(:host, host(opts))
    |> Map.put(:port, @default_port)
    |> Map.put(:scheme, @default_scheme)
  end

  defp host(opts), do: Keyword.get(opts, :host, @default_host)

  def handle_parent_response({:ok, %Response{body: body, status: 200}}) do
    Jason.decode(body)
  end
end
