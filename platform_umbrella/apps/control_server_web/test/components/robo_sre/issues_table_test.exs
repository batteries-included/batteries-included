defmodule ControlServerWeb.RoboSRE.IssuesTableTest do
  use Heyya.SnapshotCase

  import ControlServerWeb.RoboSRE.IssuesTable

  describe "issues_table/1" do
    component_snapshot_test "renders empty issues table" do
      assigns = %{issues: []}

      ~H"""
      <.issues_table rows={@issues} />
      """
    end

    component_snapshot_test "renders issues table with issues" do
      issues = [
        %{
          id: "batt_issue_1",
          subject: "cluster-1.pod.test-app",
          issue_type: :stuck_kubestate,
          status: :detected,
          handler: :pod_restart_handler,
          updated_at: ~U[2023-10-01 10:00:00Z]
        },
        %{
          id: "batt_issue_2",
          subject: "cluster-1.control_server.main",
          issue_type: :stale_resource,
          status: :remediating,
          handler: nil,
          updated_at: ~U[2023-10-01 11:30:00Z]
        },
        %{
          id: "batt_issue_3",
          subject: "cluster-1.cluster_resource.monitoring-config",
          issue_type: :stuck_kubestate,
          status: :resolved,
          handler: :resource_cleanup_handler,
          updated_at: ~U[2023-10-01 09:15:00Z]
        }
      ]

      assigns = %{issues: issues}

      ~H"""
      <.issues_table rows={@issues} />
      """
    end

    component_snapshot_test "renders abridged issues table" do
      issues = [
        %{
          id: "batt_issue_1",
          subject: "cluster-1.pod.test-app",
          issue_type: :stuck_kubestate,
          status: :failed,
          handler: :pod_restart_handler,
          updated_at: ~U[2023-10-01 10:00:00Z]
        }
      ]

      assigns = %{issues: issues}

      ~H"""
      <.issues_table rows={@issues} abridged />
      """
    end

    component_snapshot_test "renders paginated issues table" do
      issues = [
        %{
          id: "batt_issue_1",
          subject: "cluster-1.pod.test-app",
          issue_type: :stuck_kubestate,
          status: :analyzing,
          handler: nil,
          updated_at: ~U[2023-10-01 10:00:00Z]
        }
      ]

      meta = %Flop.Meta{
        current_page: 1,
        current_offset: 0,
        page_size: 20,
        total_count: 1,
        total_pages: 1
      }

      assigns = %{issues: issues, meta: meta}

      ~H"""
      <.issues_table rows={@issues} meta={@meta} />
      """
    end
  end
end
