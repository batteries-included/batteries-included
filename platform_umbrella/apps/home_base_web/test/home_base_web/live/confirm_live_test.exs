defmodule HomeBaseWeb.ConfirmLiveTest do
  use HomeBaseWeb.ConnCase, async: true

  import HomeBase.Factory
  import Phoenix.LiveViewTest

  alias HomeBase.Accounts
  alias HomeBase.Repo

  setup do
    user = :user |> params_for() |> register_user!()
    {:ok, user: user}
  end

  describe "Confirm user" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/confirm/some-token")
      assert html =~ "Confirm your account"
    end

    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/confirm/#{token}")

      result =
        lv
        |> element("button", "Confirm your account")
        |> render_click()
        |> follow_redirect(conn, ~p"/login")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :success) =~
               "User confirmed successfully"

      assert Accounts.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(Accounts.UserToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/confirm/#{token}")

      result =
        lv
        |> element("button", "Confirm your account")
        |> render_click()
        |> follow_redirect(conn, ~p"/login")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Link is invalid or it has expired"

      # when logged in
      conn =
        log_in_user(build_conn(), user)

      {:ok, lv, _html} = live(conn, ~p"/confirm/#{token}")

      result =
        lv
        |> element("button", "Confirm your account")
        |> render_click()
        |> follow_redirect(conn, ~p"/")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> element("button", "Confirm your account")
        |> render_click()
        |> follow_redirect(conn, ~p"/login")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Link is invalid or it has expired"

      refute Accounts.get_user!(user.id).confirmed_at
    end
  end
end
