defmodule ControlServer.SnapshotApply.UmbrellaTest do
  use ControlServer.DataCase

  alias ControlServer.SnapshotApply

  describe "umbrella_snapshots" do
    import ControlServer.SnapshotApplyFixtures

    alias ControlServer.SnapshotApply.UmbrellaSnapshot

    test "list_umbrella_snapshots/0 returns all umbrella_snapshots" do
      umbrella_snapshot = umbrella_snapshot_fixture()
      assert SnapshotApply.list_umbrella_snapshots() == [umbrella_snapshot]
    end

    test "get_umbrella_snapshot!/1 returns the umbrella_snapshot with given id" do
      umbrella_snapshot = umbrella_snapshot_fixture()
      assert SnapshotApply.get_umbrella_snapshot!(umbrella_snapshot.id) == umbrella_snapshot
    end

    test "create_umbrella_snapshot/1 with valid data creates a umbrella_snapshot" do
      valid_attrs = %{}

      assert {:ok, %UmbrellaSnapshot{} = _umbrella_snapshot} =
               SnapshotApply.create_umbrella_snapshot(valid_attrs)
    end

    test "update_umbrella_snapshot/2 with valid data updates the umbrella_snapshot" do
      umbrella_snapshot = umbrella_snapshot_fixture()
      update_attrs = %{}

      assert {:ok, %UmbrellaSnapshot{} = _umbrella_snapshot} =
               SnapshotApply.update_umbrella_snapshot(umbrella_snapshot, update_attrs)
    end

    test "delete_umbrella_snapshot/1 deletes the umbrella_snapshot" do
      umbrella_snapshot = umbrella_snapshot_fixture()

      assert {:ok, %UmbrellaSnapshot{}} =
               SnapshotApply.delete_umbrella_snapshot(umbrella_snapshot)

      assert_raise Ecto.NoResultsError, fn ->
        SnapshotApply.get_umbrella_snapshot!(umbrella_snapshot.id)
      end
    end

    test "change_umbrella_snapshot/1 returns a umbrella_snapshot changeset" do
      umbrella_snapshot = umbrella_snapshot_fixture()
      assert %Ecto.Changeset{} = SnapshotApply.change_umbrella_snapshot(umbrella_snapshot)
    end
  end
end
