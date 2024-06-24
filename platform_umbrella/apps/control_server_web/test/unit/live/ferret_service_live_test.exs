defmodule ControlServerWeb.FerretServiceLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServer.FerretDBFixtures
  import Phoenix.LiveViewTest

  defp create_ferret_service(_) do
    ferret_service = ferret_service_fixture()
    %{ferret_service: ferret_service}
  end

  describe "Index" do
    setup [:create_ferret_service]

    test "lists all ferret_services", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/ferretdb")

      assert html =~ "Listing FerretDB services"
    end
  end

  describe "Show" do
    setup [:create_ferret_service]

    test "displays ferret_service", %{conn: conn, ferret_service: ferret_service} do
      {:ok, _show_live, html} = live(conn, ~p"/ferretdb/#{ferret_service}/show")

      assert html =~ "Show FerretDB Service"
    end
  end
end
