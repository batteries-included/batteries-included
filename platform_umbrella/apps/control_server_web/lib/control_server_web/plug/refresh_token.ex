defmodule ControlServerWeb.Plug.RefreshToken do
  @moduledoc false
  import Plug.Conn

  alias ControlServerWeb.Plug.SessionID
  alias KubeServices.Keycloak.TokenStorage
  alias KubeServices.Keycloak.UserClient
  alias KubeServices.SystemState.SummaryBatteries

  require Logger

  def init(opts \\ []) do
    opts
  end

  def call(conn, _opts) do
    cond do
      !battery_services_running?() ->
        conn

      !SummaryBatteries.battery_installed?(:sso) ->
        conn

      true ->
        session_id = SessionID.get_session_id(conn)
        sso_token = TokenStorage.get_token(session_id)
        maybe_refresh(conn, sso_token)
    end
  end

  defp maybe_refresh(conn, nil), do: conn

  defp maybe_refresh(conn, sso_token) do
    if OAuth2.AccessToken.expired?(sso_token) do
      # Refresh the token
      case UserClient.refresh_token(sso_token) do
        {:ok, new_token} ->
          # Update the ETS table
          session_id = SessionID.get_session_id(conn)
          :ok = TokenStorage.put_token(session_id, new_token)
          conn

        {:error, _reason} ->
          remove_token(conn)

        _ ->
          remove_token(conn)
      end
    else
      conn
    end
  end

  defp remove_token(conn) do
    session_id = SessionID.get_session_id(conn)

    Logger.info("Removing token for session_id: #{session_id}")
    TokenStorage.delete_token(session_id)

    configure_session(conn, drop: true)
  end

  defp battery_services_running?, do: KubeServices.Application.start_services?()
end
