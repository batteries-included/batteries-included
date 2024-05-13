defmodule HomeBaseWeb.StoredUsageReportControllerTest do
  use HomeBaseWeb.ConnCase

  @create_attrs %{
    node_report: %{},
    namespace_report: %{},
    postgres_report: %{},
    redis_report: %{},
    num_projects: 0,
    batteries: []
  }
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create stored_usage_report" do
    test "renders stored_usage_report when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/usage_reports", usage_report: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]
      assert HomeBase.ET.get_stored_usage_report!(id) != nil
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/usage_reports", usage_report: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end
