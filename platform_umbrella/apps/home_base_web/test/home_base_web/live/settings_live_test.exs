defmodule HomeBaseWeb.SettingsLiveTest do
  use HomeBaseWeb.ConnCase, async: true

  import Ecto.Query

  alias CommonCore.Accounts.User
  alias CommonCore.Teams.Team
  alias CommonCore.Teams.TeamRole
  alias HomeBase.Accounts
  alias HomeBase.Accounts.UserToken

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
      {:ok, _lv, html} = conn |> log_in_user(user) |> live(~p"/settings")

      assert html =~ "Resend confirmation email"
      assert html =~ "Change your email"
      assert html =~ "Change your password"
      refute html =~ "Your Team"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/login"
      assert %{"error" => "You must log in to access this page"} = flash
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = :user |> params_for() |> register_user!()
      email = unique_user_email()
      {:ok, token} = Accounts.get_user_update_email_token(%{user | email: email}, user.email)

      %{conn: log_in_user(conn, user), token: token, email: email, user: user}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/settings/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/settings"
      assert %{"success" => message} = flash
      assert message == "Email changed successfully"
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/settings/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/settings"
      assert %{"error" => message} = flash
      assert message == "Link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      {:error, redirect} = live(conn, ~p"/settings/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/settings"
      assert %{"error" => message} = flash
      assert message == "Link is invalid or it has expired"
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/settings/#{token}")
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
      {:ok, lv, _html} = live(conn, ~p"/settings")

      assert lv
             |> element("a", "Resend confirmation email")
             |> render_click() =~ "Email resent"

      assert Repo.get_by!(UserToken, user_id: user.id, context: "confirm")
      assert_email_sent(to: [{"", user.email}])
    end

    test "does not send confirmation token if user is confirmed", %{conn: conn, user: user} do
      Repo.update!(User.confirm_changeset(user))

      {:ok, lv, _html} = live(conn, ~p"/settings")

      refute has_element?(lv, "a", "Resend confirmation email")
      refute Repo.get_by(UserToken, user_id: user.id, context: "confirm")
      refute_email_sent()
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

      {:ok, lv, _html} = live(conn, ~p"/settings")

      result =
        lv
        |> form("#email-form", %{
          "current_password" => password,
          "user" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
      assert_email_sent(to: [{"", new_email}])
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

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
      {:ok, lv, _html} = live(conn, ~p"/settings")

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

      {:ok, lv, _html} = live(conn, ~p"/settings")

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

      assert redirected_to(new_password_conn) == ~p"/settings"

      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :success) =~
               "Password updated successfully"

      assert Accounts.get_user_by_email_and_password(user.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/settings")

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
      {:ok, lv, _html} = live(conn, ~p"/settings")

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

  describe "update team form" do
    @valid_attrs %{"name" => "new-name", "op_email" => "new-email@test.com"}
    @invalid_attrs %{"name" => "personal", "op_email" => "invalid"}

    setup [:register_and_log_in_user, :create_and_switch_to_team]

    test "should render validation errors", ctx do
      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      assert view
             |> element("#update-team-form")
             |> render_change(%{"team" => @invalid_attrs}) =~ escape("can't be \"personal\"")
    end

    test "should render submit errors", ctx do
      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      assert view
             |> element("#update-team-form")
             |> render_submit(%{"team" => @invalid_attrs}) =~ escape("can't be \"personal\"")
    end

    test "should update the team details", ctx do
      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      view
      |> element("#update-team-form")
      |> render_submit(%{"team" => @valid_attrs})

      assert_redirected(view, ~p"/teams/#{ctx.team.id}")
      assert team = Repo.get!(Team, ctx.team.id)
      assert team.name == "new-name"
      assert team.op_email == "new-email@test.com"
    end

    test "should not show form if not an admin", ctx do
      team = insert(:team)
      insert(:team_role, team: team, user: ctx.user, is_admin: false)

      assert {:ok, view, _} = ctx.conn |> put_session(:team_id, team.id) |> live(~p"/settings")
      refute has_element?(view, "#update-team-form")
    end
  end

  describe "update team roles form" do
    @valid_attrs %{invited_email: "jane@doe.com", is_admin: false}
    @invalid_attrs %{invited_email: "invalid", is_admin: false}

    setup [:register_and_log_in_user, :create_and_switch_to_team]

    test "should render validation errors", ctx do
      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      assert view
             |> element("#new-role-form")
             |> render_change(%{"team_role" => @invalid_attrs}) =~ "must have the @ sign"
    end

    test "should render submit errors", ctx do
      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      assert view
             |> element("#new-role-form")
             |> render_submit(%{"team_role" => %{invited_email: ctx.user.email}}) =~ "already on team"
    end

    test "should create a new role", ctx do
      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      assert view
             |> element("#new-role-form")
             |> render_submit(%{"team_role" => @valid_attrs}) =~ @valid_attrs.invited_email

      assert role = Repo.get_by!(TeamRole, invited_email: @valid_attrs.invited_email)
      assert has_element?(view, "#update-role-form-#{role.id}")
      assert_email_sent(to: [{"", @valid_attrs.invited_email}])
    end

    test "should update a role", ctx do
      role = insert(:team_role, team: ctx.team, user: insert(:user))

      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      assert view
             |> element("#update-role-form-#{role.id}")
             |> render_change(%{"team_role" => %{is_admin: true}})

      assert Repo.get!(TeamRole, role.id).is_admin
    end

    test "should delete a role", ctx do
      user = insert(:user)
      role = insert(:team_role, team: ctx.team, user: user)

      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      refute view
             |> element("#update-role-form-#{role.id} ~ button")
             |> render_click() =~ role.id

      refute Repo.get(TeamRole, role.id)
      assert_email_sent(to: [{"", user.email}])
    end

    test "should not show actions for current user role", ctx do
      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")
      refute has_element?(view, "#update-role-form-#{ctx.role.id}")
    end

    test "should not delete role if not an admin", ctx do
      role = insert(:team_role, team: ctx.team, user: insert(:user))

      Repo.update_all(from(r in TeamRole, where: r.id == ^ctx.role.id), set: [is_admin: false])

      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")
      assert render_hook(view, :delete_role, %{"id" => role.id}) =~ escape("don't have permission")
      assert Repo.get!(TeamRole, role.id)
      refute_email_sent()
    end
  end

  describe "team danger zone" do
    setup [:register_and_log_in_user, :create_and_switch_to_team]

    test "should delete team", ctx do
      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      view
      |> element("button", "Delete Team")
      |> render_click()

      assert_redirected(view, ~p"/teams/personal")
      refute Repo.get(Team, ctx.team.id)
    end

    test "should not show delete team button if not an admin", ctx do
      team = insert(:team)
      insert(:team_role, team: team, user: ctx.user, is_admin: false)

      assert {:ok, _, html} = ctx.conn |> put_session(:team_id, team.id) |> live(~p"/settings")
      refute html =~ "Delete Team"
    end

    test "should not delete team if not an admin", ctx do
      Repo.update_all(from(r in TeamRole, where: r.id == ^ctx.role.id), set: [is_admin: false])

      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")
      assert render_hook(view, :delete_team, %{"id" => ctx.team.id}) =~ escape("don't have permission")
      assert Repo.get!(Team, ctx.team.id)
    end

    test "should leave team", ctx do
      insert(:team_role, team: ctx.team, user: insert(:user), is_admin: true)

      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      view
      |> element("button", "Leave Team")
      |> render_click()

      assert_redirected(view, ~p"/teams/personal")
      refute Repo.get(TeamRole, ctx.role.id)
      refute_email_sent()
    end

    test "should not leave team if last admin", ctx do
      assert {:ok, view, _} = live(ctx.conn, ~p"/settings")

      assert view
             |> element("button", "Leave Team")
             |> render_click() =~ "must have at least one admin"

      assert Repo.get(TeamRole, ctx.role.id)
    end
  end
end
