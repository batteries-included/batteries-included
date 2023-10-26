defmodule ControlServer.SnapshotApply.ReapTest do
  use ControlServer.DataCase

  describe "SnapshotApply.reap_old_snapshots/1" do
    import ControlServer.SnapshotApplyFixtures

    alias ControlServer.SnapshotApply.Umbrella

    test "reaps old snapshots" do
      _old_snapshot = umbrella_snapshot_fixture(%{inserted_at: DateTime.add(DateTime.utc_now(), -100, :hour)})
      new_snapshot = umbrella_snapshot_fixture(%{inserted_at: DateTime.add(DateTime.utc_now(), -1, :hour)})

      assert 1 == Umbrella.reap_old_snapshots(10)
      assert Umbrella.get_umbrella_snapshot!(new_snapshot.id) == new_snapshot
    end
  end
end
