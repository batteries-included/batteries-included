defmodule ControlServer.Projects.ProjectSnapshotTest do
  use ControlServer.DataCase

  import ControlServer.Factory

  alias ControlServer.Projects.Snapshoter

  setup do
    full_project = insert(:project)

    _ = insert(:postgres_cluster, project_id: full_project.id)
    _ = insert(:traditional_service, project_id: full_project.id)
    _ = insert(:traditional_service, project_id: full_project.id)

    %{
      empty_project: insert(:project),
      non_empty_project: full_project
    }
  end

  describe "Snapshotter" do
    test "should take snapshot of the project", %{empty_project: p} do
      assert {:ok, snapshot} = Snapshoter.take_snapshot(p)
      assert snapshot.description == p.description
    end

    test "should take snapshot of the project with resources", %{non_empty_project: p} do
      assert {:ok, snapshot} = Snapshoter.take_snapshot(p)
      assert snapshot.description == p.description

      assert snapshot.postgres_clusters != []
      assert 1 == length(snapshot.postgres_clusters)
      assert snapshot.traditional_services != []
      assert 2 == length(snapshot.traditional_services)
    end

    test "captured_at should be set to current time", %{empty_project: p} do
      before_time = DateTime.utc_now()
      assert {:ok, snapshot} = Snapshoter.take_snapshot(p)
      after_time = DateTime.utc_now()

      assert DateTime.compare(before_time, snapshot.captured_at) != :gt
      assert DateTime.compare(after_time, snapshot.captured_at) != :lt
    end
  end
end
