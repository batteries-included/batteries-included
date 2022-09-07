defmodule ControlServerWeb.UserSessionController do
  use ControlServerWeb, :controller

  alias ControlServer.Accounts
  alias ControlServerWeb.UserAuth
  alias ControlServerWeb.Endpoint

  def new(conn, params) do
    case UserAuth.check_logged_in(conn, params) do
      {false, updated_conn} ->
        updated_conn |> assign_create_path(params) |> render("new.html", error_message: nil)

      # The already logged in users are redirected in UserAuth
      {_, result_conn} ->
        result_conn
    end
  end

  def create(conn, %{"user" => user_params} = params) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> assign_create_path(params)
      |> render("new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  defp assign_create_path(conn, %{"login_challenge" => login_challenge} = _params) do
    path = Routes.user_session_path(Endpoint, :create, login_challenge: login_challenge)

    assign(conn, :create_path, path)
  end

  defp assign_create_path(conn, _params) do
    assign(conn, :create_path, Routes.user_session_path(Endpoint, :create))
  end
end
