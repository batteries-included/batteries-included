defmodule HomeBaseWeb.ForgotPasswordLiveTest do
  use HomeBaseWeb.ConnCase, async: true

  alias HomeBase.Accounts.UserToken

  def setup_user(_) do
    user = :user |> params_for() |> register_user!()
    {:ok, user: user}
  end

  describe "Forgot password page" do
    setup [:setup_user]

    test "renders email page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/reset")
      assert html =~ "Forgot your password?"
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      result =
        conn
        |> log_in_user(user)
        |> live(~p"/reset")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup [:setup_user]

    test "sends a new reset password token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/reset")

      {:ok, conn} =
        lv
        |> form("#reset-password-form", %{"email" => user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/login")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Please check your email"

      assert Repo.get_by!(UserToken, user_id: user.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/reset")

      {:ok, conn} =
        lv
        |> form("#reset-password-form", %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/login")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Please check your email"
      assert Repo.all(UserToken) == []
    end
  end
end
