defmodule ControlServerWeb.RoboSRE.IssueStatusBadgeTest do
  use Heyya.SnapshotCase

  import ControlServerWeb.RoboSRE.IssueStatusBadge

  describe "issue_status_badge/1" do
    component_snapshot_test "detected status" do
      assigns = %{}

      ~H"""
      <.issue_status_badge status={:detected} />
      """
    end

    component_snapshot_test "analyzing status" do
      assigns = %{}

      ~H"""
      <.issue_status_badge status={:analyzing} />
      """
    end

    component_snapshot_test "planning status" do
      assigns = %{}

      ~H"""
      <.issue_status_badge status={:planning} />
      """
    end

    component_snapshot_test "remediating status" do
      assigns = %{}

      ~H"""
      <.issue_status_badge status={:remediating} />
      """
    end

    component_snapshot_test "verifying status" do
      assigns = %{}

      ~H"""
      <.issue_status_badge status={:verifying} />
      """
    end

    component_snapshot_test "resolved status" do
      assigns = %{}

      ~H"""
      <.issue_status_badge status={:resolved} />
      """
    end

    component_snapshot_test "failed status" do
      assigns = %{}

      ~H"""
      <.issue_status_badge status={:failed} />
      """
    end

    component_snapshot_test "unknown status defaults to detected" do
      assigns = %{}

      ~H"""
      <.issue_status_badge status={:unknown} />
      """
    end

    component_snapshot_test "with custom class" do
      assigns = %{}

      ~H"""
      <.issue_status_badge status={:resolved} class="ml-4" />
      """
    end
  end
end
