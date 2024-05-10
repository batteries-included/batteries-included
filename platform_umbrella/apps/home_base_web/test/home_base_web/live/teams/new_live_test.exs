defmodule HomeBaseWeb.TeamsNewLiveTest do
  use HomeBaseWeb.ConnCase, async: true

  alias HomeBase.Teams.Team

  @valid_params %{"name" => "Foobar", "op_email" => "foo@bar.com"}
  @invalid_params %{"name" => "Personal", "op_email" => "invalid"}

  setup :register_and_log_in_user

  test "should redirect when not logged in", ctx do
    assert {:error, {:redirect, redirect}} = ctx.conn |> log_out_user() |> live(~p"/teams/new")
    assert redirect.to == ~p"/login"
  end

  test "should render disconnected page", ctx do
    assert html = ctx.conn |> get(~p"/teams/new") |> html_response(200)
    assert html =~ "new-team-form"
  end

  test "should render connected page", ctx do
    assert {:ok, _, html} = live(ctx.conn, ~p"/teams/new")
    assert html =~ "new-team-form"

    # should show one empty role input
    assert html =~ ~s|name="team[roles][0][invited_email]"|
  end

  test "should render validation errors", ctx do
    assert {:ok, view, _} = live(ctx.conn, ~p"/teams/new")

    assert view
           |> element("#new-team-form")
           |> render_change(%{"team" => @invalid_params}) =~ escape("can't be \"personal\"")
  end

  test "should render submit errors", ctx do
    assert {:ok, view, _} = live(ctx.conn, ~p"/teams/new")

    assert view
           |> element("#new-team-form")
           |> render_submit(%{"team" => @invalid_params}) =~ escape("can't be \"personal\"")
  end

  test "should add and remove team role input", ctx do
    assert {:ok, view, _} = live(ctx.conn, ~p"/teams/new")

    # should not show role input intially
    refute view
           |> element("#new-team-form")
           |> render_change() =~ ~s|name="team[roles][1][invited_email]"|

    # should show role input when added
    assert view
           |> element("#new-team-form")
           |> render_change(%{"team" => %{"sort_roles" => ["0", "new"]}}) =~ ~s|name="team[roles][1][invited_email]"|

    # should not show role input when removed
    refute view
           |> element("#new-team-form")
           |> render_change(%{"team" => %{"drop_roles" => ["1"]}}) =~ ~s|name="team[roles][1][invited_email]"|
  end

  test "should create a new team and switch to it", ctx do
    assert {:ok, view, _} = live(ctx.conn, ~p"/teams/new")

    view
    |> element("#new-team-form")
    |> render_submit(%{"team" => @valid_params})

    assert %{id: id} = Repo.get_by!(Team, name: "Foobar")
    assert_redirected(view, ~p"/teams/#{id}?redirect_to=/")
  end
end
