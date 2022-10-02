defmodule ControlServer.SeedTest do
  use ControlServer.DataCase

  alias ControlServer.Release
  alias ControlServer.Postgres
  alias ControlServer.Batteries.SystemBattery

  import ExUnit.CaptureIO

  describe "ControlServer.Seed" do
    def battery_count, do: Repo.aggregate(SystemBattery, :count)
    def postgres_count, do: Repo.aggregate(Postgres.Cluster, :count)

    test "its idempotent" do
      capture_io(fn ->
        assert 0 == battery_count()
        assert 0 == postgres_count()

        Release.seed_prod()

        assert 8 == battery_count()
        assert 1 == postgres_count()

        Release.seed_prod()

        assert 8 == battery_count()
        assert 1 == postgres_count()
      end)
    end
  end
end
