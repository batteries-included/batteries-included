defmodule ControlServerWeb.Plug.ApiSSOAuth do
  @moduledoc false

  import Phoenix.Controller
  import Plug.Conn

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
      !SummaryBatteries.battery_installed?(:sso) ->
        conn

      # In test mode we don't require sso as there's no kubernetes
      !battery_services_running?() ->
        conn

      valid_token?(conn) ->
        conn

      true ->
        unauthorized(conn)
    end
  end

  def valid_token?(conn) do
    token =
      conn
      |> get_req_header("authorization")
      # Remove "Bearer " from the token
      |> Enum.map(fn header -> header |> String.replace("Bearer ", "") |> String.trim() end)
      |> List.last()

    token_ok?(token)
  end

  defp token_ok?(nil), do: false

  defp token_ok?(token) do
    case UserClient.userinfo(token) do
      {:ok, _} -> true
      _ -> false
    end
  end

  def unauthorized(conn) do
    conn
    |> put_status(401)
    |> json(%{error: "Unauthorized"})
    |> halt()
  end

  def battery_services_running?, do: KubeServices.Application.start_services?()
end
