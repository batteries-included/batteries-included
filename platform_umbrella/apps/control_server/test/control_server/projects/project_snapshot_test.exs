defmodule ControlServer.Projects.ProjectSnapshotTest do
  use ControlServer.DataCase

  import ControlServer.Factory

  alias ControlServer.Projects.Snapshoter

  defp non_empty_project do
    full_project = insert(:project)

    pg_cluster = insert(:postgres_cluster, project_id: full_project.id)
    traditional_service_zero = insert(:traditional_service, project_id: full_project.id, virtual_size: "tiny")

    traditional_service_one =
      insert(:traditional_service, project_id: full_project.id, num_instances: 1, virtual_size: "small")

    %{
      full_project: full_project,
      full_project_pg_cluster: pg_cluster,
      full_project_traditional_service_zero: traditional_service_zero,
      full_project_traditional_service_one: traditional_service_one
    }
  end

  defp ferretdb_project do
    project = insert(:project)
    pg_cluster = insert(:postgres_cluster, project_id: project.id)
    ferret_db = insert(:ferret_service, project_id: project.id, postgres_cluster_id: pg_cluster.id)

    %{
      ferretdb_project: project,
      ferretdb_project_pg_cluster: pg_cluster,
      ferretdb_project_ferret_db: ferret_db
    }
  end

  defp small_pg_project do
    project = insert(:project)
    pg_cluster = insert(:postgres_cluster, project_id: project.id, virtual_size: "small")

    %{
      small_pg_project: project,
      small_pg_project_pg_cluster: pg_cluster
    }
  end

  setup do
    %{empty_project: insert(:project)}
    |> Map.merge(non_empty_project())
    |> Map.merge(ferretdb_project())
    |> Map.merge(small_pg_project())
  end

  describe "Snapshotter" do
    test "should take snapshot of the project", %{empty_project: p} do
      assert {:ok, snapshot} = Snapshoter.take_snapshot(p)
      assert snapshot.description == p.description
    end

    test "should take snapshot of the project with resources", %{full_project: p} do
      assert {:ok, snapshot} = Snapshoter.take_snapshot(p)

      assert snapshot.description == p.description

      assert snapshot.postgres_clusters != []
      assert 1 == length(snapshot.postgres_clusters)
      assert snapshot.traditional_services != []
      assert 2 == length(snapshot.traditional_services)
    end

    test "should include ferret_services", %{ferretdb_project: project} do
      assert {:ok, snapshot} = Snapshoter.take_snapshot(project)
      assert snapshot.description == project.description

      assert snapshot.postgres_clusters != []
      assert 1 == length(snapshot.postgres_clusters)
      assert snapshot.ferret_services != []
      assert 1 == length(snapshot.ferret_services)
    end

    test "should change references", %{ferretdb_project: project} do
      assert {:ok, snapshot} = Snapshoter.take_snapshot(project)
      assert snapshot.description == project.description

      # Remove the ferretdb servbices and the postgres clusters
      # from the database so that we can re-apply the snapshot
      # without any conflicts

      Enum.each(snapshot.ferret_services, fn db ->
        assert {:ok, _} = ControlServer.FerretDB.delete_ferret_service(db)
      end)

      Enum.each(snapshot.postgres_clusters, fn pg ->
        assert {:ok, _} = ControlServer.Postgres.delete_cluster(pg)
      end)

      # Now we can re-apply the snapshot
      assert {:ok, _} = Snapshoter.apply_snapshot(project, snapshot)

      refetched = ControlServer.Projects.get_project!(project.id)

      assert refetched.postgres_clusters != []
      assert 1 == length(refetched.postgres_clusters)
      assert refetched.ferret_services != []
      assert 1 == length(refetched.ferret_services)

      assert refetched.ferret_services |> List.first() |> Map.get(:postgres_cluster_id) ==
               List.first(refetched.postgres_clusters).id
    end

    test "apply can override virtual_size", %{small_pg_project: project} do
      assert {:ok, snapshot} = Snapshoter.take_snapshot(project)

      from_snapshot = List.first(snapshot.postgres_clusters)

      # Remove the postgres cluster from the database so that we can re-apply the snapshot
      # without any conflicts
      assert {:ok, _} = ControlServer.Postgres.delete_cluster(List.first(snapshot.postgres_clusters))

      # Now we can re-apply the snapshot
      assert {:ok, _} = Snapshoter.apply_snapshot(project, snapshot, virtual_size: "huge")

      refetched = ControlServer.Projects.get_project!(project.id)

      assert refetched.postgres_clusters != []
      assert 1 == length(refetched.postgres_clusters)

      cluster = List.first(refetched.postgres_clusters)

      assert cluster.cpu_requested >= from_snapshot.cpu_requested
      assert cluster.memory_requested >= from_snapshot.memory_requested
      assert cluster.memory_limits >= from_snapshot.memory_limits
    end

    test "setting virtual size works on larger projects", %{full_project: project} do
      assert {:ok, snapshot} = Snapshoter.take_snapshot(project)

      from_snapshot = List.first(snapshot.postgres_clusters)

      # Remove the postgres cluster from the database so that we can re-apply the snapshot
      # without any conflicts
      assert {:ok, _} = ControlServer.Postgres.delete_cluster(List.first(snapshot.postgres_clusters))

      # Now we can re-apply the snapshot
      assert {:ok, _} = Snapshoter.apply_snapshot(project, snapshot, virtual_size: "huge")

      refetched = ControlServer.Projects.get_project!(project.id)

      assert refetched.postgres_clusters != []
      assert 1 == length(refetched.postgres_clusters)

      cluster = List.first(refetched.postgres_clusters)

      assert cluster.cpu_requested >= from_snapshot.cpu_requested
      assert cluster.memory_requested >= from_snapshot.memory_requested
      assert cluster.memory_limits >= from_snapshot.memory_limits
    end
  end

  describe "Snapshot Process is secure" do
    test "Removes the pasword_versions from postgres clusters", %{small_pg_project: p} do
      assert {:ok, snapshot} = Snapshoter.take_snapshot(p)
      assert snapshot.postgres_clusters != []
      assert 1 == length(snapshot.postgres_clusters)

      snap_cluster = List.first(snapshot.postgres_clusters)

      assert snap_cluster.password_versions == []
    end

    test "import doesn't change postgres passwords", %{
      small_pg_project: p,
      small_pg_project_pg_cluster: pg_cluster
    } do
      assert {:ok, snapshot} = Snapshoter.take_snapshot(p)
      assert {:ok, _} = Snapshoter.apply_snapshot(p, snapshot)

      refetched = ControlServer.Postgres.get_cluster!(pg_cluster.id)

      assert refetched.password_versions != []

      assert refetched.password_versions == pg_cluster.password_versions
    end
  end
end
