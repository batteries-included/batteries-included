defmodule HomeBaseWeb.SignupLiveTest do
  use HomeBaseWeb.ConnCase, async: true

  defp setup_user(_) do
    user = :user |> params_for() |> register_user!()
    %{user: user}
  end

  defp unique_user_email do
    "user_#{Base.encode16(:crypto.strong_rand_bytes(8))}@example.com"
  end

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/signup")

      assert html =~ "Sign up"
      assert html =~ "Log in"
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/signup")

      result =
        lv
        |> element("#signup-form")
        |> render_change(user: %{"email" => "w spce", "password" => "too sht"})

      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 8 character"
      assert result =~ "must be accepted"
    end

    test "prefills email address from url query", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/signup?email=jane%40doe.com")

      assert lv |> element("[name=\"user[email]\"]") |> render() =~ "jane@doe.com"
    end
  end

  describe "Registration page when logged in" do
    setup [:setup_user]

    test "redirects if already logged in", %{conn: conn, user: user} do
      result =
        conn
        |> log_in_user(user)
        |> live(~p"/signup")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end
  end

  describe "register user" do
    test "creates account and logs the user in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/signup")

      email = unique_user_email()

      user_params =
        :user
        |> params_for(email: email, hashed_password: nil)
        |> Map.merge(%{terms: true, password: "HelloWorld123!", password_confirmation: "HelloWorld123!"})

      form = form(lv, "#signup-form", user: user_params)
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/installations/new"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ "Settings"
      assert response =~ "Log out"
      assert_email_sent(to: [{"", email}])
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/signup")

      user = :user |> params_for(%{email: "test@email.com"}) |> register_user!()

      result =
        lv
        |> form("#signup-form",
          user: %{"email" => user.email, "password" => "valid_password"}
        )
        |> render_submit()

      assert result =~ "has already been taken"
      refute_email_sent()
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/signup")

      {:ok, _login_live, login_html} =
        lv
        |> element("a", "Log in")
        |> render_click()
        |> follow_redirect(conn, ~p"/login")

      assert login_html =~ "Log in"
    end
  end
end
