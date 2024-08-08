defmodule ControlServer.SnapshotApply.UmbrellaTest do
  use ControlServer.DataCase

  alias ControlServer.SnapshotApply.Umbrella

  describe "umbrella_snapshots" do
    import ControlServer.SnapshotApplyFixtures

    alias ControlServer.SnapshotApply.UmbrellaSnapshot

    test "list_umbrella_snapshots/0 returns all umbrella snapshots" do
      umbrella_snapshot = umbrella_snapshot_fixture()
      assert Umbrella.list_umbrella_snapshots() == [umbrella_snapshot]
    end

    test "list_umbrella_snapshots/1 returns paginated umbrella snapshots" do
      _umbrella_snapshot1 = umbrella_snapshot_fixture()
      umbrella_snapshot2 = umbrella_snapshot_fixture()

      assert {:ok, {[umbrella_snapshot], _}} = Umbrella.list_umbrella_snapshots(%{limit: 1})
      assert umbrella_snapshot.id == umbrella_snapshot2.id
    end

    test "get_umbrella_snapshot!/1 returns the umbrella_snapshot with given id" do
      umbrella_snapshot = umbrella_snapshot_fixture()
      assert Umbrella.get_umbrella_snapshot!(umbrella_snapshot.id) == umbrella_snapshot
    end

    test "create_umbrella_snapshot/1 with valid data creates a umbrella_snapshot" do
      valid_attrs = %{}

      assert {:ok, %UmbrellaSnapshot{} = _umbrella_snapshot} =
               Umbrella.create_umbrella_snapshot(valid_attrs)
    end

    test "update_umbrella_snapshot/2 with valid data updates the umbrella_snapshot" do
      umbrella_snapshot = umbrella_snapshot_fixture()
      update_attrs = %{}

      assert {:ok, %UmbrellaSnapshot{} = _umbrella_snapshot} =
               Umbrella.update_umbrella_snapshot(umbrella_snapshot, update_attrs)
    end

    test "delete_umbrella_snapshot/1 deletes the umbrella_snapshot" do
      umbrella_snapshot = umbrella_snapshot_fixture()

      assert {:ok, %UmbrellaSnapshot{}} =
               Umbrella.delete_umbrella_snapshot(umbrella_snapshot)

      assert_raise Ecto.NoResultsError, fn ->
        Umbrella.get_umbrella_snapshot!(umbrella_snapshot.id)
      end
    end

    test "change_umbrella_snapshot/1 returns a umbrella_snapshot changeset" do
      umbrella_snapshot = umbrella_snapshot_fixture()
      assert %Ecto.Changeset{} = Umbrella.change_umbrella_snapshot(umbrella_snapshot)
    end
  end

  describe "latest_umbrella_snapshots/1" do
    import ControlServer.SnapshotApplyFixtures

    test "returns latest umbrella snapshots" do
      for _i <- 1..20, do: umbrella_snapshot_fixture()

      snapshots = Umbrella.latest_umbrella_snapshots(10)
      assert is_list(snapshots)
      assert length(snapshots) <= 10
    end

    test "returns empty list if no snapshots exist" do
      snapshots = Umbrella.latest_umbrella_snapshots(10)
      assert snapshots == []
    end
  end
end
