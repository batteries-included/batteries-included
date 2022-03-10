defmodule ControlServer.SeedTest do
  use ControlServer.DataCase

  alias ControlServer.Release
  alias ControlServer.Postgres
  alias ControlServer.Services

  describe "ControlServer.Seed" do
    def baseservice_count, do: Repo.aggregate(Services.BaseService, :count)
    def postgres_count, do: Repo.aggregate(Postgres.Cluster, :count)

    test "its idempotent" do
      assert 0 == baseservice_count()
      assert 0 == postgres_count()

      Release.seed()

      assert 5 == baseservice_count()
      assert 1 == postgres_count()

      Release.seed()

      assert 5 == baseservice_count()
      assert 1 == postgres_count()
    end
  end
end
