defmodule ControlServer.SnapshotApply.KubeTest do
  use ControlServer.DataCase

  alias ControlServer.SnapshotApply.Kube

  describe "resource_paths" do
    alias ControlServer.SnapshotApply.ResourcePath

    import ControlServer.KubeSnapshotApplyFixtures

    @invalid_attrs %{
      hash: nil,
      path: nil,
      name: nil,
      kind: nil,
      api_version: nil
    }

    test "list_resource_paths/0 returns all resource_paths" do
      resource_path = resource_path_fixture()
      assert Kube.list_resource_paths() == [resource_path]
    end

    test "get_resource_path!/1 returns the resource_path with given id" do
      resource_path = resource_path_fixture()
      assert Kube.get_resource_path!(resource_path.id) == resource_path
    end

    test "create_resource_path/1 with valid data creates a resource_path" do
      valid_attrs = %{
        hash: "some hash",
        path: "some path",
        name: "some name",
        type: :pod
      }

      assert {:ok, %ResourcePath{} = resource_path} = Kube.create_resource_path(valid_attrs)

      assert resource_path.hash == "some hash"
      assert resource_path.path == "some path"
    end

    test "create_resource_path/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Kube.create_resource_path(@invalid_attrs)
    end

    test "update_resource_path/2 with valid data updates the resource_path" do
      resource_path = resource_path_fixture()

      update_attrs = %{
        hash: "some updated hash",
        path: "some updated path",
        resource_value: %{test_value: 100, other: [42]}
      }

      assert {:ok, %ResourcePath{} = resource_path} =
               Kube.update_resource_path(resource_path, update_attrs)

      assert resource_path.hash == "some updated hash"
      assert resource_path.path == "some updated path"
    end

    test "update_resource_path/2 with invalid data returns error changeset" do
      resource_path = resource_path_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Kube.update_resource_path(resource_path, @invalid_attrs)

      assert resource_path == Kube.get_resource_path!(resource_path.id)
    end

    test "delete_resource_path/1 deletes the resource_path" do
      resource_path = resource_path_fixture()
      assert {:ok, %ResourcePath{}} = Kube.delete_resource_path(resource_path)

      assert_raise Ecto.NoResultsError, fn ->
        Kube.get_resource_path!(resource_path.id)
      end
    end

    test "change_resource_path/1 returns a resource_path changeset" do
      resource_path = resource_path_fixture()
      assert %Ecto.Changeset{} = Kube.change_resource_path(resource_path)
    end
  end

  describe "kube_snapshots" do
    alias ControlServer.SnapshotApply.KubeSnapshot

    import ControlServer.KubeSnapshotApplyFixtures

    @invalid_attrs %{status: nil}

    test "list_kube_snapshots/0 returns all kube_snapshots" do
      kube_snapshot = kube_snapshot_fixture()
      assert Kube.list_kube_snapshots() == [kube_snapshot]
    end

    test "get_kube_snapshot!/1 returns the kube_snapshot with given id" do
      kube_snapshot = kube_snapshot_fixture()
      assert Kube.get_kube_snapshot!(kube_snapshot.id) == kube_snapshot
    end

    test "create_kube_snapshot/1 with valid data creates a kube_snapshot" do
      valid_attrs = %{status: :creation}

      assert {:ok, %KubeSnapshot{} = kube_snapshot} = Kube.create_kube_snapshot(valid_attrs)

      assert kube_snapshot.status == :creation
    end

    test "create_kube_snapshot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Kube.create_kube_snapshot(@invalid_attrs)
    end

    test "update_kube_snapshot/2 with valid data updates the kube_snapshot" do
      kube_snapshot = kube_snapshot_fixture()
      update_attrs = %{status: :generation}

      assert {:ok, %KubeSnapshot{} = kube_snapshot} =
               Kube.update_kube_snapshot(kube_snapshot, update_attrs)

      assert kube_snapshot.status == :generation
    end

    test "update_kube_snapshot/2 with invalid data returns error changeset" do
      kube_snapshot = kube_snapshot_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Kube.update_kube_snapshot(kube_snapshot, @invalid_attrs)

      assert kube_snapshot == Kube.get_kube_snapshot!(kube_snapshot.id)
    end

    test "delete_kube_snapshot/1 deletes the kube_snapshot" do
      kube_snapshot = kube_snapshot_fixture()
      assert {:ok, %KubeSnapshot{}} = Kube.delete_kube_snapshot(kube_snapshot)

      assert_raise Ecto.NoResultsError, fn ->
        Kube.get_kube_snapshot!(kube_snapshot.id)
      end
    end

    test "change_kube_snapshot/1 returns a kube_snapshot changeset" do
      kube_snapshot = kube_snapshot_fixture()
      assert %Ecto.Changeset{} = Kube.change_kube_snapshot(kube_snapshot)
    end

    @tag :slow
    test "get_latest_snapshot_status!/0 returns the latest kube_snapshot status" do
      update_attrs_success = %{status: :ok}
      update_attrs_fail = %{status: :error}

      _kube_snapshot_oldest = kube_snapshot_fixture()
      _kube_snapshot_older = kube_snapshot_fixture()
      kube_snapshot_success = kube_snapshot_fixture()

      # status => :creation by default
      assert Kube.get_latest_snapshot_status() === nil

      # update latest snapshot to succeed
      Kube.update_kube_snapshot(kube_snapshot_success, update_attrs_success)
      assert Kube.get_latest_snapshot_status() === :ok

      # create a new snapshot and fail it
      kube_snapshot_fail = kube_snapshot_fixture()
      Kube.update_kube_snapshot(kube_snapshot_fail, update_attrs_fail)
      assert Kube.get_latest_snapshot_status() === :error
    end
  end
end
