defmodule ControlServerWeb.BackendIndexLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "index" do
    test "renders an empty list of backend services", %{conn: conn} do
      conn
      |> start(~p|/backend/services|)
      |> assert_html("Backend Services")
    end

    test "renders a list of backend services", %{conn: conn} do
      insert(:backend_service, name: "Service 1")
      insert(:backend_service, name: "Service 2")

      conn
      |> start(~p|/backend/services|)
      |> assert_html("Service 1")
      |> assert_html("Service 2")
    end
  end
end
