defmodule HomeBaseWeb.UserSessionController do
  use HomeBaseWeb, :controller

  alias HomeBase.Accounts
  alias HomeBaseWeb.UserAuth

  def create(conn, %{"action" => "registered"} = params) do
    create(conn, params, {:global_warning, "Check your email to verify your account"})
  end

  def create(conn, %{"action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/settings")
    |> create(params, {:success, "Password updated successfully!"})
  end

  def create(conn, params) do
    create(conn, params, {:global_info, "Welcome back!"})
  end

  defp create(conn, %{"user" => user_params}, {flash_type, flash_msg}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(flash_type, flash_msg)
      |> UserAuth.log_in_user(user, user_params)
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
