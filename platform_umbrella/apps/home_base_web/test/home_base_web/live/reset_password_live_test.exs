defmodule HomeBaseWeb.ResetPasswordLiveTest do
  use HomeBaseWeb.ConnCase, async: true

  alias HomeBase.Accounts

  setup do
    user = :user |> params_for() |> register_user!()

    token =
      extract_user_token(fn url ->
        Accounts.deliver_user_reset_password_instructions(user, url)
      end)

    %{token: token, user: user}
  end

  describe "Reset password page" do
    test "renders reset password with valid token", %{conn: conn, token: token, user: user} do
      {:ok, _lv, html} = live(conn, ~p"/reset/#{token}")

      assert html =~ "Reset your password"
      assert html =~ user.email
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      {:error, {:redirect, to}} = live(conn, ~p"/reset/invalid")

      assert to == %{
               flash: %{"error" => "Link is invalid or has expired"},
               to: ~p"/login"
             }
    end

    test "renders errors for invalid data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/reset/#{token}")

      result =
        lv
        |> element("#reset-password-form")
        |> render_change(user: %{"password" => "short", "password_confirmation" => "secret123456"})

      assert result =~ "should be at least 8 character"
      assert result =~ "does not match password"
    end
  end

  describe "Reset Password" do
    test "resets password once", %{conn: conn, token: token, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/reset/#{token}")

      {:ok, conn} =
        lv
        |> form("#reset-password-form",
          user: %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/login")

      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :success) =~ "Password successfully reset"
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/reset/#{token}")

      result =
        lv
        |> form("#reset-password-form",
          user: %{
            "password" => "toosht",
            "password_confirmation" => "does not match"
          }
        )
        |> render_submit()

      assert result =~ "should be at least 8 character(s)"
      assert result =~ "does not match password"
    end
  end
end
