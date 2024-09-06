defmodule ControlServerWeb.Plug.SSOAuth do
  @moduledoc false

  import Phoenix.Controller
  import Plug.Conn

  alias ControlServerWeb.Plug.SessionID
  alias KubeServices.Keycloak.TokenStorage
  alias KubeServices.Keycloak.UserClient
  alias KubeServices.SystemState.SummaryBatteries

  def init(opts \\ []) do
    opts
  end

  def call(conn, opts) do
    maybe_require_sso(conn, opts)
  end

  defp maybe_require_sso(conn, _opts) do
    cond do
      # There's no sso so let them in
      !SummaryBatteries.battery_installed(:sso) ->
        conn

      # In test mode we don't require sso as there's no kubernetes
      !battery_services_running?() ->
        conn

      # If there's a token let them in
      conn
      |> SessionID.get_session_id()
      |> TokenStorage.get_token() != nil ->
        conn

      true ->
        redirect_to_oauth(conn)
    end
  end

  def redirect_to_oauth(conn) do
    with {:ok, url} <- UserClient.authorize_url(UserClient, return_to: return_to(conn)) do
      conn
      |> redirect(external: url)
      |> halt()
    end
  end

  def battery_services_running?, do: KubeServices.Application.start_services?()

  # request_url(conn) will always return http when running in cluster as TLS is terminated by istio / envoy
  # so set scheme if x-forwarded-proto is set or ssl is enabled
  defp return_to(conn) do
    uri = conn |> request_url() |> URI.parse()
    forward_proto = conn |> get_req_header("x-forwarded-proto") |> List.first()

    scheme =
      cond do
        !is_nil(forward_proto) ->
          forward_proto

        SummaryBatteries.ssl_enabled?() ->
          "https"

        true ->
          uri.scheme
      end

    uri |> determine_uri(scheme) |> URI.to_string()
  end

  defp determine_uri(uri, new_scheme)
  defp determine_uri(%URI{} = uri, nil), do: uri
  defp determine_uri(%URI{} = uri, ""), do: uri
  defp determine_uri(%URI{scheme: old_scheme} = uri, new_scheme) when old_scheme == new_scheme, do: uri

  defp determine_uri(%URI{scheme: "http", port: 80} = uri, "https"),
    do: uri |> Map.put(:scheme, "https") |> Map.put(:port, 443)

  # leave port alone if switching from http -> https and we're not on the default port - 80
  defp determine_uri(%URI{scheme: "http"} = uri, "https"), do: Map.put(uri, :scheme, "https")
end
