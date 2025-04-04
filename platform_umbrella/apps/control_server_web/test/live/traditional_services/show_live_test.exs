defmodule ControlServerWeb.TraditionalServices.ShowLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "Traditional Services Show Page" do
    test "renders the show page with service details", %{conn: conn} do
      # Create a service to test
      service = insert(:traditional_service, name: "Test Service", kube_deployment_type: :deployment)

      # Navigate to the show page
      conn
      |> start(~p"/traditional_services/#{service.id}/show")
      |> assert_html("Traditional Service")
      |> assert_html(service.name)
    end

    test "includes Actions dropdown", %{conn: conn} do
      service = insert(:traditional_service, name: "Test Service", kube_deployment_type: :deployment)

      conn
      |> start(~p"/traditional_services/#{service.id}/show")
      |> assert_html("Actions")
      |> assert_html("Edit")
      |> assert_html("Delete")
    end
  end
end
