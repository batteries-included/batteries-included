defmodule HomeBaseWeb.ProfileLiveTest do
  use HomeBaseWeb.ConnCase, async: true

  import HomeBase.Factory
  import Phoenix.LiveViewTest

  alias HomeBase.Accounts

  defp setup_user(_) do
    {:ok, user: :user |> params_for() |> register_user!()}
  end

  defp valid_user_password do
    # Create a random password that is at least 8 characters long
    8 |> :crypto.strong_rand_bytes() |> Base.encode64()
  end

  defp unique_user_email do
    "user_#{Base.encode16(:crypto.strong_rand_bytes(8))}@example.com"
  end

  describe "Settings page" do
    setup [:setup_user]

    test "renders settings page", %{conn: conn, user: user} do
      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/profile")

      assert html =~ "Resend confirmation email"
      assert html =~ "Change your email"
      assert html =~ "Change your password"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/profile")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/login"
      assert %{"error" => "You must log in to access this page"} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = :user |> params_for(%{password: password}) |> register_user!()

      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user email", %{conn: conn, password: password, user: user} do
      new_email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/profile")

      result =
        lv
        |> form("#email-form", %{
          "current_password" => password,
          "user" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/profile")

      result =
        lv
        |> element("#email-form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/profile")

      result =
        lv
        |> form("#email-form", %{
          "current_password" => "invalid",
          "user" => %{"email" => user.email}
        })
        |> render_submit()

      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_user_password()
      user = :user |> params_for(%{password: password}) |> register_user!()
      %{conn: log_in_user(conn, user), user: user, password: password}
    end

    test "updates the user password", %{conn: conn, user: user, password: password} do
      new_password = valid_user_password()

      {:ok, lv, _html} = live(conn, ~p"/profile")

      form =
        form(lv, "#password-form", %{
          "current_password" => password,
          "user" => %{
            "email" => user.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/profile"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :success) =~
               "Password updated successfully"

      assert Accounts.get_user_by_email_and_password(user.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/profile")

      result =
        lv
        |> element("#password-form")
        |> render_change(%{
          "current_password" => "invalid",
          "user" => %{
            "password" => "tooshrt",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "should be at least 8 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/profile")

      result =
        lv
        |> form("#password-form", %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "tooshrt",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "should be at least 8 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = :user |> params_for() |> register_user!()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{conn: log_in_user(conn, user), token: token, email: email, user: user}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/profile/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/profile"
      assert %{"success" => message} = flash
      assert message == "Email changed successfully"
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/profile/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/profile"
      assert %{"error" => message} = flash
      assert message == "Link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      {:error, redirect} = live(conn, ~p"/profile/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/profile"
      assert %{"error" => message} = flash
      assert message == "Link is invalid or it has expired"
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/profile/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/login"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page"
    end
  end

  describe "resend confirmation email" do
    setup [:setup_user]

    setup %{conn: conn, user: user} do
      %{conn: log_in_user(conn, user)}
    end

    test "sends a new confirmation token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/profile")

      assert lv
             |> element(~s|a:fl-contains("Resend confirmation email")|)
             |> render_click() =~ "Email resent"

      assert Repo.get_by!(Accounts.UserToken, user_id: user.id, context: "confirm")
    end

    test "does not send confirmation token if user is confirmed", %{conn: conn, user: user} do
      Repo.update!(Accounts.User.confirm_changeset(user))

      {:ok, lv, _html} = live(conn, ~p"/profile")

      refute has_element?(lv, ~s|a:fl-contains("Resend confirmation email")|)
      refute Repo.get_by(Accounts.UserToken, user_id: user.id, context: "confirm")
    end
  end
end
