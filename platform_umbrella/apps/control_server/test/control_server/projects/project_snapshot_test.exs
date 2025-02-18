defmodule ControlServer.Projects.ProjectSnapshotTest do
  use ControlServer.DataCase

  import ControlServer.Factory

  alias ControlServer.Projects.Snapshoter

  setup do
    full_project = insert(:project)

    pg_cluster = insert(:postgres_cluster, project_id: full_project.id)
    traditional_service_zero = insert(:traditional_service, project_id: full_project.id, virtual_size: "tiny")

    traditional_service_one =
      insert(:traditional_service, project_id: full_project.id, num_instances: 1, virtual_size: "small")

    %{
      empty_project: insert(:project),
      non_empty_project: full_project,
      pg_cluster: pg_cluster,
      traditional_service_zero: traditional_service_zero,
      traditional_service_one: traditional_service_one
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
  end
end
