defmodule ControlServerWeb.GroupBatteries.EditLiveTest do
  use ControlServerWeb.ConnCase, async: true

  test "should render disconnected page", ctx do
    assert html = ctx.conn |> get(~p"/batteries/magic/edit/battery_core") |> html_response(200)
    assert html =~ "Battery Core Battery"
  end

  test "should render connected page", ctx do
    assert {:ok, _, html} = live(ctx.conn, ~p"/batteries/magic/edit/battery_core")
    assert html =~ "Battery Core Battery"
  end

  test "should edit a battery", ctx do
    assert {:ok, view, _} = live(ctx.conn, ~p"/batteries/magic/edit/battery_core")

    assert {:ok, _, html} =
             view
             |> element("#edit-batteries-form")
             |> render_submit()
             |> follow_redirect(ctx.conn, ~p"/batteries/magic")

    assert html =~ "Battery has been updated"
  end
end
