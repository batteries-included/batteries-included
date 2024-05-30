defmodule HomeBaseWeb.StoredHostReportControllerTest do
  use HomeBaseWeb.ConnCase

  import HomeBase.Factory

  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json"), installation: insert(:installation)}
  end

  describe "create stored_host_report" do
    test "renders stored_host_report when data is valid", %{conn: conn, installation: install} do
      host_report = params_for(:host_report)

      conn = post(conn, ~p"/api/v1/installations/#{install.id}/host_reports", host_report: host_report)

      assert %{"id" => id} = json_response(conn, 201)["data"]
      report = HomeBase.ET.get_stored_host_report!(id)
      assert report != nil
      assert report.installation_id == install.id
    end

    test "renders errors when data is invalid", %{conn: conn, installation: install} do
      conn = post(conn, ~p"/api/v1/installations/#{install.id}/host_reports", host_report: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "renders errors when installation_id is invalid", %{conn: conn} do
      host_report = params_for(:host_report)
      installation_id = CommonCore.Ecto.BatteryUUID.autogenerate()

      conn = post(conn, ~p"/api/v1/installations/#{installation_id}/host_reports", host_report: host_report)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end
