defmodule ControlServerWeb.ServiceLiveTest do
  use ControlServerWeb.ConnCase

  import Phoenix.LiveViewTest
  import ControlServer.KnativeFixtures

  defp create_service(_) do
    service = service_fixture()
    %{service: service}
  end

  describe "Index" do
    setup [:create_service]

    test "lists all services", %{conn: conn, service: service} do
      {:ok, _index_live, html} = live(conn, ~p"/knative/services")

      assert html =~ "Listing Services"
      assert html =~ service.name
    end
  end
end
