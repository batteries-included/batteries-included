defmodule HomeBaseWeb.UsageReportLiveTest do
  use HomeBaseWeb.ConnCase

  import Phoenix.LiveViewTest

  alias HomeBase.Usage

  @create_attrs %{
    external_id: "7488a646-e31f-11e4-aace-600308960662",
    generated_at: "2010-04-17T14:00:00Z",
    pod_report: %{},
    node_report: %{},
    num_nodes: 42,
    num_pods: 44
  }

  defp fixture(:usage_report) do
    {:ok, usage_report} = Usage.create_usage_report(@create_attrs)
    usage_report
  end

  defp create_usage_report(_) do
    usage_report = fixture(:usage_report)
    %{usage_report: usage_report}
  end

  describe "Index" do
    setup [:create_usage_report]

    test "lists all usage_reports", %{conn: conn, usage_report: _usage_report} do
      {:ok, _index_live, html} = live(conn, Routes.usage_report_index_path(conn, :index))

      assert html =~ "Listing Usage reports"
    end
  end

  describe "Show" do
    setup [:create_usage_report]

    test "displays usage_report", %{conn: conn, usage_report: usage_report} do
      {:ok, _show_live, html} =
        live(conn, Routes.usage_report_show_path(conn, :show, usage_report))

      assert html =~ "Show Usage report"
    end
  end
end
