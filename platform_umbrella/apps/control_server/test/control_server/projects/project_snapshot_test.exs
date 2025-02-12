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

    test "captured_at should be set to current time", %{empty_project: p} do
      before_time = DateTime.utc_now()
      assert {:ok, snapshot} = Snapshoter.take_snapshot(p)
      after_time = DateTime.utc_now()

      assert DateTime.compare(before_time, snapshot.captured_at) != :gt
      assert DateTime.compare(after_time, snapshot.captured_at) != :lt
    end

    test "should apply a captured_snapshot to a project", %{
      non_empty_project: p,
      pg_cluster: pg,
      traditional_service_zero: ts_zero,
      traditional_service_one: ts_one
    } do
      {:ok, snapshot} = Snapshoter.take_snapshot(p)

      assert {:ok, _} = ControlServer.Postgres.delete_cluster(pg)
      assert {:ok, _} = ControlServer.TraditionalServices.delete_service(ts_zero)

      # rather than deleting the service we'll make some changes
      assert {:ok, _} =
               ControlServer.TraditionalServices.update_service(ts_one, %{num_instances: 420, virtual_size: "huge"})

      assert {:ok, _} = Snapshoter.apply_snapshot(p, snapshot)

      assert fetched = ControlServer.Projects.get_project(p.id)

      assert fetched.postgres_clusters != []
      assert 1 == length(fetched.postgres_clusters)

      assert fetched.traditional_services != []
      assert 2 == length(fetched.traditional_services)

      # assert that the update changed the service back to its original state
      assert ControlServer.TraditionalServices.get_service!(ts_one.id).num_instances == ts_one.num_instances
    end
  end
end
