defmodule ControlServerWeb.GroupBatteries.NewLiveTest do
  use ControlServerWeb.ConnCase, async: true

  test "should render disconnected page", ctx do
    assert html = ctx.conn |> get(~p"/batteries/magic/new/timeline") |> html_response(200)
    assert html =~ "Timeline Battery"
  end

  test "should render connected page", ctx do
    assert {:ok, _, html} = live(ctx.conn, ~p"/batteries/magic/new/timeline")
    assert html =~ "Timeline Battery"
  end

  test "should install a new battery", ctx do
    assert {:ok, view, _} = live(ctx.conn, ~p"/batteries/magic/new/timeline")

    assert view
           |> element("#new-batteries-form")
           |> render_submit() =~ "Installing Timeline"
  end
end
