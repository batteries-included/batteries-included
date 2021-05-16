defmodule ControlServerWeb.UsageReportControllerTest do
  use ControlServerWeb.ConnCase

  alias ControlServer.Usage
  alias ControlServer.Usage.UsageReport

  @create_attrs %{
    namespace_report: %{},
    node_report: %{},
    reported_nodes: 42
  }
  @update_attrs %{
    namespace_report: %{},
    node_report: %{},
    reported_nodes: 43
  }

  def fixture(:usage_report) do
    {:ok, usage_report} = Usage.create_usage_report(@create_attrs)
    usage_report
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all usage_reports", %{conn: conn} do
      conn = get(conn, Routes.usage_report_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create usage_report" do
    test "renders usage_report when data is valid", %{conn: conn} do
      conn = post(conn, Routes.usage_report_path(conn, :create), usage_report: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.usage_report_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "namespace_report" => %{},
               "node_report" => %{},
               "reported_nodes" => 42
             } = json_response(conn, 200)["data"]
    end
  end

  describe "update usage_report" do
    setup [:create_usage_report]

    test "renders usage_report when data is valid", %{
      conn: conn,
      usage_report: %UsageReport{id: id} = usage_report
    } do
      conn =
        put(conn, Routes.usage_report_path(conn, :update, usage_report),
          usage_report: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.usage_report_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "namespace_report" => %{},
               "node_report" => %{},
               "reported_nodes" => 43
             } = json_response(conn, 200)["data"]
    end
  end

  describe "delete usage_report" do
    setup [:create_usage_report]

    test "deletes chosen usage_report", %{conn: conn, usage_report: usage_report} do
      conn = delete(conn, Routes.usage_report_path(conn, :delete, usage_report))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.usage_report_path(conn, :show, usage_report))
      end
    end
  end

  defp create_usage_report(_) do
    usage_report = fixture(:usage_report)
    %{usage_report: usage_report}
  end
end
