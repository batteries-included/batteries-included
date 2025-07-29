defmodule HomeBase.ETTest do
  use HomeBase.DataCase

  alias HomeBase.ET

  describe "stored_usage_reports" do
    import HomeBase.Factory

    alias HomeBase.ET.StoredUsageReport

    @invalid_attrs %{report: nil}

    test "list_stored_usage_reports/0 returns all stored_usage_reports" do
      stored_usage_report = insert(:stored_usage_report)
      assert Enum.map(ET.list_stored_usage_reports(), & &1.id) == [stored_usage_report.id]
    end

    test "get_stored_usage_report!/1 returns the stored_usage_report with given id" do
      stored_usage_report = insert(:stored_usage_report)

      assert ET.get_stored_usage_report!(stored_usage_report.id).id == stored_usage_report.id
    end

    test "create_stored_usage_report/1 with valid data creates a stored_usage_report" do
      install = insert(:installation)
      valid_attrs = params_for(:stored_usage_report, installation_id: install.id)

      assert {:ok, %StoredUsageReport{} = _stored_usage_report} = ET.create_stored_usage_report(valid_attrs)
    end

    test "create_stored_usage_report/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ET.create_stored_usage_report(@invalid_attrs)
    end

    test "update_stored_usage_report/2 with valid data updates the stored_usage_report" do
      stored_usage_report = insert(:stored_usage_report)
      report = build(:usage_report)
      update_attrs = %{report: report}

      assert {:ok, %StoredUsageReport{} = stored_usage_report} =
               ET.update_stored_usage_report(stored_usage_report, update_attrs)

      assert stored_usage_report.report == report
    end

    test "update_stored_usage_report/2 with invalid data returns error changeset" do
      stored_usage_report = insert(:stored_usage_report)
      assert {:error, %Ecto.Changeset{}} = ET.update_stored_usage_report(stored_usage_report, @invalid_attrs)
      assert stored_usage_report.id == ET.get_stored_usage_report!(stored_usage_report.id).id
      assert stored_usage_report.report == ET.get_stored_usage_report!(stored_usage_report.id).report
    end

    test "delete_stored_usage_report/1 deletes the stored_usage_report" do
      stored_usage_report = insert(:stored_usage_report)
      assert {:ok, %StoredUsageReport{}} = ET.delete_stored_usage_report(stored_usage_report)
      assert_raise Ecto.NoResultsError, fn -> ET.get_stored_usage_report!(stored_usage_report.id) end
    end

    test "soft_delete_stored_usage_report/1 deletes the stored_usage_report" do
      stored_usage_report = insert(:stored_usage_report)
      assert {:ok, %StoredUsageReport{}} = ET.soft_delete_stored_usage_report(stored_usage_report)
      assert_raise Ecto.NoResultsError, fn -> ET.get_stored_usage_report!(stored_usage_report.id) end

      # assert that there's still a record and that it's "soft" deleted
      all_reports = Repo.list_with_soft_deleted(StoredUsageReport)
      assert length(all_reports) == 1

      found = List.first(all_reports)
      assert stored_usage_report.id == found.id
      assert found.deleted_at
    end

    test "soft deleted usage reports are still readable" do
      stored_usage_report = insert(:stored_usage_report)
      assert {:ok, %StoredUsageReport{}} = ET.soft_delete_stored_usage_report(stored_usage_report)

      # assert that there's still a record and that it's "soft" deleted
      all_reports = Repo.list_with_soft_deleted(StoredUsageReport)
      assert length(all_reports) == 1

      found = List.first(all_reports)
      assert stored_usage_report.id == found.id
      assert found.deleted_at
    end

    test "change_stored_usage_report/1 returns a stored_usage_report changeset" do
      stored_usage_report = insert(:stored_usage_report)
      assert %Ecto.Changeset{} = ET.change_stored_usage_report(stored_usage_report)
    end
  end

  describe "stored_host_reports" do
    import HomeBase.Factory

    alias HomeBase.ET.StoredHostReport

    @invalid_attrs %{report: nil}

    test "list_stored_host_reports/0 returns all stored_host_reports" do
      stored_host_report = insert(:stored_host_report)
      assert Enum.map(ET.list_stored_host_reports(), & &1.id) == [stored_host_report.id]
    end

    test "get_stored_host_report!/1 returns the stored_host_report with given id" do
      stored_host_report = insert(:stored_host_report)

      assert ET.get_stored_host_report!(stored_host_report.id).id == stored_host_report.id
    end

    test "create_stored_host_report/1 with valid data creates a stored_host_report" do
      install = insert(:installation)
      valid_attrs = params_for(:stored_host_report, installation_id: install.id)

      assert {:ok, %StoredHostReport{} = _stored_host_report} = ET.create_stored_host_report(valid_attrs)
    end

    test "create_stored_host_report/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ET.create_stored_host_report(@invalid_attrs)
    end

    test "update_stored_host_report/2 with valid data updates the stored_host_report" do
      stored_host_report = insert(:stored_host_report)
      report = build(:host_report)
      update_attrs = %{report: report}

      assert {:ok, %StoredHostReport{} = stored_host_report} =
               ET.update_stored_host_report(stored_host_report, update_attrs)

      assert stored_host_report.report == report
    end

    test "update_stored_host_report/2 with invalid data returns error changeset" do
      stored_host_report = insert(:stored_host_report)
      assert {:error, %Ecto.Changeset{}} = ET.update_stored_host_report(stored_host_report, @invalid_attrs)
      assert stored_host_report.id == ET.get_stored_host_report!(stored_host_report.id).id
      assert stored_host_report.report == ET.get_stored_host_report!(stored_host_report.id).report
    end

    test "delete_stored_host_report/1 deletes the stored_host_report" do
      stored_host_report = insert(:stored_host_report)
      assert {:ok, %StoredHostReport{}} = ET.delete_stored_host_report(stored_host_report)
      assert_raise Ecto.NoResultsError, fn -> ET.get_stored_host_report!(stored_host_report.id) end
    end

    test "soft_delete_stored_host_report/1 deletes the stored_host_report" do
      stored_host_report = insert(:stored_host_report)
      assert {:ok, %StoredHostReport{}} = ET.soft_delete_stored_host_report(stored_host_report)
      assert_raise Ecto.NoResultsError, fn -> ET.get_stored_host_report!(stored_host_report.id) end

      # assert that there's still a record and that it's "soft" deleted
      all_reports = Repo.list_with_soft_deleted(StoredHostReport)
      assert length(all_reports) == 1

      found = List.first(all_reports)
      assert stored_host_report.id == found.id
      assert found.deleted_at
    end

    test "soft deleted host reports are still readable" do
      stored_host_report = insert(:stored_host_report)
      assert {:ok, %StoredHostReport{}} = ET.soft_delete_stored_host_report(stored_host_report)

      # assert that there's still a record and that it's "soft" deleted
      all_reports = Repo.list_with_soft_deleted(StoredHostReport)
      assert length(all_reports) == 1

      found = List.first(all_reports)
      assert stored_host_report.id == found.id
      assert found.deleted_at
    end

    test "change_stored_host_report/1 returns a stored_host_report changeset" do
      stored_host_report = insert(:stored_host_report)
      assert %Ecto.Changeset{} = ET.change_stored_host_report(stored_host_report)
    end
  end
end
