defmodule ControlServerWeb.SystemBatteryLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServer.BatteriesFixtures
  import Phoenix.LiveViewTest

  defp create_system_battery(_) do
    system_battery = system_battery_fixture()
    %{system_battery: system_battery}
  end

  describe "Index" do
    setup [:create_system_battery]

    test "lists all system_batteries", %{conn: conn, system_battery: system_battery} do
      {:ok, _index_live, html} = live(conn, ~p"/system_batteries")

      assert html =~ "Listing System batteries"
      assert html =~ Atom.to_string(system_battery.group)
    end

    @tag :slow
    test "deletes system_battery in listing", %{conn: conn, system_battery: system_battery} do
      {:ok, index_live, _html} = live(conn, ~p"/system_batteries")

      assert index_live
             |> element("#system_batteries-#{system_battery.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#system_battery-#{system_battery.id}")
    end
  end

  describe "Show" do
    setup [:create_system_battery]

    test "displays system_battery", %{conn: conn, system_battery: system_battery} do
      {:ok, _show_live, html} = live(conn, ~p"/system_batteries/#{system_battery.id}")

      assert html =~ "Show System battery"
      assert html =~ Atom.to_string(system_battery.group)
    end
  end
end
