defmodule HomeBaseWeb.UsageReportControllerTest do
  use HomeBaseWeb.ConnCase

  alias HomeBase.Usage
  alias HomeBase.Usage.UsageReport

  @create_attrs %{
    external_id: "7488a646-e31f-11e4-aace-600308960662",
    generated_at: "2010-04-17T14:00:00Z",
    namespace_report: %{},
    node_report: %{},
    num_nodes: 42,
    num_pods: 43
  }
  @update_attrs %{
    external_id: "7488a646-e31f-11e4-aace-600308960668",
    generated_at: "2011-05-18T15:01:01Z",
    namespace_report: %{},
    node_report: %{},
    num_nodes: 44,
    num_pods: 45
  }
  @invalid_attrs %{
    external_id: nil,
    generated_at: nil,
    namespace_report: nil,
    node_report: nil,
    num_nodes: nil,
    num_pods: nil
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
               "external_id" => "7488a646-e31f-11e4-aace-600308960662",
               "generated_at" => "2010-04-17T14:00:00.000000Z",
               "namespace_report" => %{},
               "node_report" => %{},
               "num_nodes" => 42,
               "num_pods" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.usage_report_path(conn, :create), usage_report: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
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
               "external_id" => "7488a646-e31f-11e4-aace-600308960668",
               "generated_at" => "2011-05-18T15:01:01.000000Z",
               "namespace_report" => %{},
               "node_report" => %{},
               "num_nodes" => 44,
               "num_pods" => 45
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, usage_report: usage_report} do
      conn =
        put(conn, Routes.usage_report_path(conn, :update, usage_report),
          usage_report: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete usage_report" do
    setup [:create_usage_report]

    test "deletes chosen usage_report", %{conn: conn, usage_report: usage_report} do
      conn = delete(conn, Routes.usage_report_path(conn, :delete, usage_report))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(conn, Routes.usage_report_path(conn, :show, usage_report))
      end)
    end
  end

  defp create_usage_report(_) do
    usage_report = fixture(:usage_report)
    %{usage_report: usage_report}
  end
end
