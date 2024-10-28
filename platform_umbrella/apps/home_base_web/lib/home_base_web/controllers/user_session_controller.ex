defmodule HomeBaseWeb.UserSessionController do
  use HomeBaseWeb, :controller

  alias HomeBase.Accounts
  alias HomeBaseWeb.UserAuth

  def create(conn, %{"action" => "registered"} = params) do
    conn
    |> put_flash(:global_warning, "Check your email to verify your account")
    |> create(Map.delete(params, "action"))
  end

  def create(conn, %{"action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/settings")
    |> put_flash(:success, "Password updated successfully!")
    |> create(Map.delete(params, "action"))
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
