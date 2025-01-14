defmodule ControlServerWeb.GroupBatteries.EditLiveTest do
  use ControlServerWeb.ConnCase

  alias ControlServer.Batteries.Installer
  alias KubeServices.SystemState.Summarizer

  setup do
    timeline_report = Installer.install!(:timeline)
    Summarizer.new()

    %{system_battery: timeline_report.installed.timeline}
  end

  test "should render disconnected page", ctx do
    assert ctx.conn
           |> get(~p"/batteries/#{ctx.system_battery.group}/edit/#{ctx.system_battery.id}")
           |> html_response(200) =~ "Timeline Battery"
  end

  test "should render connected page", ctx do
    assert {:ok, _, html} = live(ctx.conn, ~p"/batteries/#{ctx.system_battery.group}/edit/#{ctx.system_battery.id}")
    assert html =~ "Timeline Battery"
  end

  test "should edit a battery", ctx do
    assert {:ok, view, _} = live(ctx.conn, ~p"/batteries/#{ctx.system_battery.group}/edit/#{ctx.system_battery.id}")

    assert {:ok, _, html} =
             view
             |> element("#edit-battery-form")
             |> render_submit()
             |> follow_redirect(ctx.conn, ~p"/batteries/#{ctx.system_battery.group}")

    assert html =~ "Battery has been updated"
  end
end
