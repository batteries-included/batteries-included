defmodule HomeBaseWeb.TeamsControllerTest do
  use HomeBaseWeb.ConnCase, async: true

  setup :register_and_log_in_user

  setup ctx do
    team = insert(:team)
    role = insert(:team_role, team: team, user: ctx.user)

    %{team: team, role: role}
  end

  describe "GET /teams/personal" do
    test "should switch back to personal account", ctx do
      conn = ctx.conn |> put_session(:team_id, ctx.team.id) |> get(~p"/teams/personal")

      refute get_session(conn, :team_id)
      assert redirected_to(conn) == ~p"/"
    end
  end

  describe "GET /teams/:team_id" do
    test "should switch the current team", ctx do
      conn = get(ctx.conn, ~p"/")
      refute get_session(conn, :team_id)

      conn = get(conn, ~p"/teams/#{ctx.team.id}")
      assert get_session(conn, :team_id) == ctx.team.id
      assert redirected_to(conn) == ~p"/"
    end

    test "should not switch to a team that user is not on", ctx do
      team = insert(:team)
      conn = get(ctx.conn, ~p"/teams/#{team.id}")

      refute get_session(conn, :team_id)
    end

    test "should not switch to a team that does not exist", ctx do
      refute ctx.conn
             |> get(~p"/teams/#{CommonCore.Util.BatteryUUID.autogenerate()}")
             |> get_session(:team_id)
    end

    test "should redirect to referer url", ctx do
      assert ctx.conn
             |> put_req_header("referer", "/foo/bar")
             |> get(~p"/teams/#{ctx.team.id}")
             |> redirected_to() == "/foo/bar"
    end

    test "should redirect to query string url", ctx do
      assert ctx.conn
             |> get(~p"/teams/#{ctx.team.id}?redirect_to=/foo/bar")
             |> redirected_to() == "/foo/bar"
    end

    test "should avoid a referer redirect loop", ctx do
      assert ctx.conn
             |> put_req_header("referer", "/teams/#{ctx.team.id}")
             |> get(~p"/teams/#{ctx.team.id}")
             |> redirected_to() == ~p"/"
    end

    test "should redirect if user is not signed in", ctx do
      assert ctx.conn
             |> log_out_user()
             |> get(~p"/teams/#{ctx.team.id}")
             |> redirected_to() == ~p"/login"
    end
  end
end
