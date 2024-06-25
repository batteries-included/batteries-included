defmodule ControlServerWeb.ServiceLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServer.KnativeFixtures
  import Phoenix.LiveViewTest

  defp create_service(_) do
    service = service_fixture()
    %{service: service}
  end

  describe "Index" do
    setup [:create_service]

    test "lists all services", %{conn: conn, service: service} do
      {:ok, _index_live, html} = live(conn, ~p"/knative/services")

      assert html =~ "Knative Services"
      assert html =~ service.name
    end
  end
end
