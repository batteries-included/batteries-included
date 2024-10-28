defmodule HomeBaseWeb.LoginLiveTest do
  use HomeBaseWeb.ConnCase, async: true

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/login")

      assert html =~ "Log in"
      assert html =~ "Sign up"
      assert html =~ "Forgot your password?"
    end
  end

  describe "Log in page while registered" do
    setup do
      %{user: :user |> params_for() |> register_user!()}
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      result =
        conn
        |> log_in_user(user)
        |> live(~p"/login")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "user login" do
    test "redirects if user login with valid credentials", %{conn: conn} do
      password = "123456789abcd"
      user = :user |> params_for(%{password: password}) |> register_user!()

      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#login-form", user: %{email: user.email, password: password, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/installations/new"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/login")

      form =
        form(lv, "#login-form", user: %{email: "test@email.com", password: "123456", remember_me: true})

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"

      assert redirected_to(conn) == ~p"/login"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/login")

      {:ok, _login_live, login_html} =
        lv
        |> element("a", "Sign up")
        |> render_click()
        |> follow_redirect(conn, ~p"/signup")

      assert login_html =~ "Sign up"
    end

    test "redirects to forgot password page when the Forgot Password button is clicked", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/login")

      {:ok, _reset_live, reset_html} =
        lv
        |> element("a", "Forgot your password?")
        |> render_click()
        |> follow_redirect(conn, ~p"/reset")

      assert reset_html =~ "Forgot your password?"
    end
  end
end
