defmodule HomeBase.UsageTest do
  use HomeBase.DataCase

  alias HomeBase.Usage

  describe "usage_reports" do
    alias HomeBase.Usage.UsageReport

    @valid_attrs %{
      external_id: "7488a646-e31f-11e4-aace-600308960662",
      generated_at: "2010-04-17T14:00:00Z",
      namespace_report: %{},
      node_report: %{},
      reported_nodes: 42
    }
    @update_attrs %{
      external_id: "7488a646-e31f-11e4-aace-600308960668",
      generated_at: "2011-05-18T15:01:01Z",
      namespace_report: %{},
      node_report: %{},
      reported_nodes: 43
    }
    @invalid_attrs %{
      external_id: nil,
      generated_at: nil,
      namespace_report: nil,
      node_report: nil,
      reported_nodes: nil
    }

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
      assert usage_report.external_id == "7488a646-e31f-11e4-aace-600308960662"

      assert usage_report.generated_at ==
               DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")

      assert usage_report.namespace_report == %{}
      assert usage_report.node_report == %{}
      assert usage_report.reported_nodes == 42
    end

    test "create_usage_report/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Usage.create_usage_report(@invalid_attrs)
    end

    test "update_usage_report/2 with valid data updates the usage_report" do
      usage_report = usage_report_fixture()

      assert {:ok, %UsageReport{} = usage_report} =
               Usage.update_usage_report(usage_report, @update_attrs)

      assert usage_report.external_id == "7488a646-e31f-11e4-aace-600308960668"

      assert usage_report.generated_at ==
               DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")

      assert usage_report.namespace_report == %{}
      assert usage_report.node_report == %{}
      assert usage_report.reported_nodes == 43
    end

    test "update_usage_report/2 with invalid data returns error changeset" do
      usage_report = usage_report_fixture()
      assert {:error, %Ecto.Changeset{}} = Usage.update_usage_report(usage_report, @invalid_attrs)
      assert usage_report == Usage.get_usage_report!(usage_report.id)
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
