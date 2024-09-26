defmodule ControlServerWeb.Plug.SSOAuth do
  @moduledoc false

  import CommonUI.UrlHelpers
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
    with {:ok, url} <- UserClient.authorize_url(UserClient, return_to: conn |> get_uri_from_conn() |> URI.to_string()) do
      conn
      |> redirect(external: url)
      |> halt()
    end
  end

  def battery_services_running?, do: KubeServices.Application.start_services?()
end
