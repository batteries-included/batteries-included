defmodule ControlServerWeb.UmbrellaSnapshotsTableTest do
  use Heyya.SnapshotTest

  import ControlServerWeb.UmbrellaSnapshotsTable

  @success_snapshot %{
    id: "success-umbrella-id",
    inserted_at: ~U[2023-02-28 07:00:00Z],
    kube_snapshot: %{id: "kube-snapshot-success-id", status: "Success"},
    keycloak_snapshot: nil
  }

  @failure_snapshot %{
    id: "failure-umbrella-id",
    inserted_at: ~U[2023-02-28 07:00:00Z],
    kube_snapshot: %{id: "kube-snapshot-failed-id", status: "Failed"},
    keycloak_snapshot: %{status: "Failed"}
  }

  describe "UmbrellaSnapshotsTable" do
    component_snapshot_test "with a no snapshots" do
      assigns = %{snapshots: []}

      ~H"""
      <.umbrella_snapshots_table snapshots={@snapshots} />
      """
    end

    component_snapshot_test "with snapshots" do
      assigns = %{snapshots: [@success_snapshot, @failure_snapshot]}

      ~H"""
      <.umbrella_snapshots_table snapshots={@snapshots} />
      """
    end
  end
end
