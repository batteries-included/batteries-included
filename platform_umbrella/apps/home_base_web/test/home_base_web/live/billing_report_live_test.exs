defmodule HomeBaseWeb.BillingReportLiveTest do
  use HomeBaseWeb.ConnCase

  import Phoenix.LiveViewTest

  alias HomeBase.Billing

  @create_attrs %{
    end: "2010-04-17T14:00:00Z",
    by_hour: %{},
    start: "2010-04-17T14:00:00Z",
    node_hours: 42,
    pod_hours: 42
  }

  defp fixture(:billing_report) do
    {:ok, billing_report} = Billing.create_billing_report(@create_attrs)
    billing_report
  end

  defp create_billing_report(_) do
    billing_report = fixture(:billing_report)
    %{billing_report: billing_report}
  end

  describe "Index" do
    setup [:create_billing_report]

    test "lists all billing_reports", %{conn: conn, billing_report: _billing_report} do
      {:ok, _index_live, html} = live(conn, Routes.billing_report_index_path(conn, :index))

      assert html =~ "Listing Billing reports"
    end
  end

  describe "Show" do
    setup [:create_billing_report]

    test "displays billing_report", %{conn: conn, billing_report: billing_report} do
      {:ok, _show_live, html} =
        live(conn, Routes.billing_report_show_path(conn, :show, billing_report))

      assert html =~ "Show Billing report"
    end
  end
end
