defmodule HomeBase.ETTest do
  use HomeBase.DataCase

  alias HomeBase.ET

  describe "stored_usage_reports" do
    import HomeBase.Factory

    alias HomeBase.ET.StoredUsageReport

    @invalid_attrs %{report: nil}

    test "list_stored_usage_reports/0 returns all stored_usage_reports" do
      stored_usage_report = insert(:stored_usage_report)
      assert ET.list_stored_usage_reports() == [stored_usage_report]
    end

    test "get_stored_usage_report!/1 returns the stored_usage_report with given id" do
      stored_usage_report = insert(:stored_usage_report)

      assert ET.get_stored_usage_report!(stored_usage_report.id) == stored_usage_report
    end

    test "create_stored_usage_report/1 with valid data creates a stored_usage_report" do
      valid_attrs = params_for(:stored_usage_report)

      assert {:ok, %StoredUsageReport{} = _stored_usage_report} = ET.create_stored_usage_report(valid_attrs)
    end

    test "create_stored_usage_report/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ET.create_stored_usage_report(@invalid_attrs)
    end

    test "update_stored_usage_report/2 with valid data updates the stored_usage_report" do
      stored_usage_report = insert(:stored_usage_report)
      report = CommonCore.Factory.usage_report_factory()
      update_attrs = %{report: report}

      assert {:ok, %StoredUsageReport{} = stored_usage_report} =
               ET.update_stored_usage_report(stored_usage_report, update_attrs)

      assert stored_usage_report.report == report
    end

    test "update_stored_usage_report/2 with invalid data returns error changeset" do
      stored_usage_report = insert(:stored_usage_report)
      assert {:error, %Ecto.Changeset{}} = ET.update_stored_usage_report(stored_usage_report, @invalid_attrs)
      assert stored_usage_report == ET.get_stored_usage_report!(stored_usage_report.id)
    end

    test "delete_stored_usage_report/1 deletes the stored_usage_report" do
      stored_usage_report = insert(:stored_usage_report)
      assert {:ok, %StoredUsageReport{}} = ET.delete_stored_usage_report(stored_usage_report)
      assert_raise Ecto.NoResultsError, fn -> ET.get_stored_usage_report!(stored_usage_report.id) end
    end

    test "change_stored_usage_report/1 returns a stored_usage_report changeset" do
      stored_usage_report = insert(:stored_usage_report)
      assert %Ecto.Changeset{} = ET.change_stored_usage_report(stored_usage_report)
    end
  end
end
