defmodule ControlServerWeb.SSOController do
  use ControlServerWeb, :controller

  alias KubeServices.Keycloak.UserClient

  def index(conn, _params) do
    redirect(conn, to: "/")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  def callback(conn, %{"code" => code} = query) do
    return_to = query |> Map.get("return_to", "/") |> URI.decode_www_form()

    with {:ok, token} <- UserClient.get_token(code: code, return_to: return_to) do
      return_to_path =
        return_to
        |> URI.parse()
        |> Map.get(:path)
        |> Kernel.||("/")

      session_id = ControlServerWeb.Plug.SessionID.get_session_id(conn)

      :ok = KubeServices.Keycloak.TokenStorage.put_token(session_id, token)

      redirect(conn, to: return_to_path)
    end
  end
end
