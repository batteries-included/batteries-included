defmodule ControlServer.RoboSRE.IssuesTest do
  use ControlServer.DataCase

  import ControlServer.Factory

  alias CommonCore.RoboSRE.Issue
  alias ControlServer.RoboSRE.Issues

  describe "issues" do
    test "list_issues/0 returns all issues" do
      issue = insert(:issue)
      assert Issues.list_issues() == [issue]
    end

    test "get_issue!/1 returns the issue with given id" do
      issue = insert(:issue)
      assert Issues.get_issue!(issue.id, preload: []) == issue
    end

    test "create_issue/1 with valid data creates an issue" do
      valid_attrs =
        params_for(:issue, %{
          subject: "test-cluster:pod:my-app:container",
          issue_type: :stuck_kubestate,
          trigger: :kubernetes_event,
          handler: :stale_resource,
          trigger_params: %{"restart_count" => 5},
          status: :detected
        })

      assert {:ok, %Issue{} = issue} = Issues.create_issue(valid_attrs)
      assert issue.subject == "test-cluster:pod:my-app:container"
      assert issue.issue_type == :stuck_kubestate
      assert issue.trigger == :kubernetes_event
      assert issue.status == :detected
      assert issue.trigger_params == %{"restart_count" => 5}
    end

    test "create_issue/1 with invalid data returns error changeset" do
      invalid_attrs = %{
        subject: nil,
        issue_type: nil,
        trigger: nil,
        status: nil
      }

      assert {:error, %Ecto.Changeset{}} = Issues.create_issue(invalid_attrs)
    end

    test "update_issue/2 with valid data updates the issue" do
      issue = insert(:issue, status: :detected)

      update_attrs = %{
        status: :analyzing
      }

      assert {:ok, %Issue{} = updated_issue} = Issues.update_issue(issue, update_attrs)
      assert updated_issue.status == :analyzing
    end

    test "update_issue/2 with invalid data returns error changeset" do
      issue = insert(:issue)
      invalid_attrs = %{subject: nil, status: nil}

      assert {:error, %Ecto.Changeset{}} = Issues.update_issue(issue, invalid_attrs)
      assert issue == Issues.get_issue!(issue.id, preload: [])
    end

    test "delete_issue/1 deletes the issue" do
      issue = insert(:issue)
      assert {:ok, %Issue{}} = Issues.delete_issue(issue)
      assert_raise Ecto.NoResultsError, fn -> Issues.get_issue!(issue.id) end
    end

    test "change_issue/1 returns an issue changeset" do
      issue = insert(:issue)
      assert %Ecto.Changeset{} = Issues.change_issue(issue)
    end

    test "find_open_issues_by_subject/1 returns open issues for subject" do
      subject = "cluster.pod.app1"

      # Create some issues
      issue1 = insert(:issue, subject: subject, status: :detected)
      issue2 = insert(:issue, subject: subject, status: :analyzing)
      _resolved_issue = insert(:issue, subject: subject, status: :resolved)
      _different_subject = insert(:issue, subject: "cluster:pod:app2", status: :detected)

      open_issues = Issues.find_open_issues_by_subject(subject)

      assert length(open_issues) == 2
      assert issue1 in open_issues
      assert issue2 in open_issues
    end

    test "count_open_issues/0 returns count of open issues" do
      insert(:issue, status: :detected)
      insert(:issue, status: :analyzing)
      # This one shouldn't be counted
      insert(:issue, status: :resolved)

      assert Issues.count_open_issues() == 2
    end

    test "mark_stale_issues_as_resolved/1 marks old issues as resolved" do
      now = DateTime.utc_now()
      # 25 hours ago
      old_time = DateTime.add(now, -25, :hour)

      # Create issues with different updated_at times
      stale_issue = insert(:issue, status: :detected, updated_at: old_time)
      recent_issue = insert(:issue, status: :detected, updated_at: now)

      {count, _} = Issues.mark_stale_issues_as_resolved(24)

      assert count == 1

      # Verify the stale issue was resolved
      updated_stale = Issues.get_issue!(stale_issue.id)
      assert updated_stale.status == :resolved
      assert updated_stale.resolved_at

      # Verify the recent issue is still open
      updated_recent = Issues.get_issue!(recent_issue.id)
      assert updated_recent.status == :detected
      refute updated_recent.resolved_at
    end
  end
end
