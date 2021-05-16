defmodule ControlServer.UsageTest do
  use ControlServer.DataCase

  alias ControlServer.Usage

  describe "usage_reports" do
    alias ControlServer.Usage.UsageReport

    @valid_attrs %{namespace_report: %{}, node_report: %{}, reported_nodes: 42}
    @update_attrs %{namespace_report: %{}, node_report: %{}, reported_nodes: 43}

    def usage_report_fixture(attrs \\ %{}) do
      {:ok, usage_report} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Usage.create_usage_report()

      usage_report
    end

    test "list_usage_reports/0 returns all usage_reports" do
      usage_report = usage_report_fixture()
      assert Usage.list_usage_reports() == [usage_report]
    end

    test "get_usage_report!/1 returns the usage_report with given id" do
      usage_report = usage_report_fixture()
      assert Usage.get_usage_report!(usage_report.id) == usage_report
    end

    test "create_usage_report/1 with valid data creates a usage_report" do
      assert {:ok, %UsageReport{} = usage_report} = Usage.create_usage_report(@valid_attrs)
      assert usage_report.namespace_report == %{}
      assert usage_report.node_report == %{}
      assert usage_report.reported_nodes == 42
    end

    test "update_usage_report/2 with valid data updates the usage_report" do
      usage_report = usage_report_fixture()

      assert {:ok, %UsageReport{} = usage_report} =
               Usage.update_usage_report(usage_report, @update_attrs)

      assert usage_report.namespace_report == %{}
      assert usage_report.node_report == %{}
      assert usage_report.reported_nodes == 43
    end

    test "delete_usage_report/1 deletes the usage_report" do
      usage_report = usage_report_fixture()
      assert {:ok, %UsageReport{}} = Usage.delete_usage_report(usage_report)
      assert_raise Ecto.NoResultsError, fn -> Usage.get_usage_report!(usage_report.id) end
    end

    test "change_usage_report/1 returns a usage_report changeset" do
      usage_report = usage_report_fixture()
      assert %Ecto.Changeset{} = Usage.change_usage_report(usage_report)
    end
  end
end
