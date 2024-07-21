defmodule ControlServerWeb.TraditionalIndexLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "index" do
    test "renders an empty list of Traditional Services", %{conn: conn} do
      conn
      |> start(~p|/traditional_services|)
      |> assert_html("Traditional Services")
    end

    test "renders a list of Traditional Services", %{conn: conn} do
      insert(:traditional_service, name: "Service 1")
      insert(:traditional_service, name: "Service 2")

      conn
      |> start(~p|/traditional_services|)
      |> assert_html("Service 1")
      |> assert_html("Service 2")
    end
  end
end
