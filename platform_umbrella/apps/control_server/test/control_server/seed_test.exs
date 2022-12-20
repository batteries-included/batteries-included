defmodule ControlServer.SeedTest do
  use ControlServer.DataCase

  alias ControlServer.Release
  alias ControlServer.Postgres
  alias ControlServer.Batteries.SystemBattery

  describe "ControlServer.Seed" do
    def battery_count, do: Repo.aggregate(SystemBattery, :count)
    def postgres_count, do: Repo.aggregate(Postgres.Cluster, :count)

    test "its idempotent" do
      assert 0 == battery_count()
      assert 0 == postgres_count()

      Release.seed()

      assert 7 == battery_count()
      assert 1 == postgres_count()

      Release.seed()

      assert 7 == battery_count()
      assert 1 == postgres_count()
    end
  end
end
