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
      {:ok, _index_live, html} = live(conn, Routes.knative_services_index_path(conn, :index))

      assert html =~ "Listing Services"
      assert html =~ service.name
    end

    test "deletes service in listing", %{conn: conn, service: service} do
      {:ok, index_live, _html} = live(conn, Routes.knative_services_index_path(conn, :index))

      assert index_live |> element("#service-#{service.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#service-#{service.id}")
    end
  end
end
