defmodule CommonCore.StateSummary.BackupsTest do
  use ExUnit.Case

  import CommonCore.Factory

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Backups

  describe "backups/2" do
    test "it doesn't fail with no backups" do
      assert [] = Backups.backups(%StateSummary{kube_state: %{}})
      assert [] = Backups.backups(%StateSummary{kube_state: %{cloudnative_pg_backup: []}})
    end

    test "it lists all backups if no cluster name provided" do
      backups = [build(:pg_backup)]
      state = %StateSummary{kube_state: %{cloudnative_pg_backup: backups}}

      assert ^backups = Backups.backups(state)
    end

    test "it lists all backups if empty string is used as cluster name" do
      backups = [build(:pg_backup)]
      state = %StateSummary{kube_state: %{cloudnative_pg_backup: backups}}

      assert ^backups = Backups.backups(state, "")
    end

    test "it filters appropriately on cluster name" do
      backup = build(:pg_backup, %{"spec" => %{"cluster" => %{"name" => "test"}}})

      all_backups = [backup] ++ Enum.map(1..10, fn _ -> build(:pg_backup) end) ++ [backup]
      state = %StateSummary{kube_state: %{cloudnative_pg_backup: all_backups}}

      found = Backups.backups(state, "test")
      assert 2 = length(found)
      Enum.each(found, &assert("test" == &1["spec"]["cluster"]["name"]))
    end
  end
end
