defmodule ControlServer.Batteries.InstallerTest do
  use ControlServer.DataCase

  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Redis.FailoverCluster
  alias CommonCore.Postgres.Cluster, as: PGCluster

  alias ControlServer.Batteries.Installer

  import CommonCore.SeedArgsConverter

  describe "ControlServer.Batteries.Installer" do
    test "every battery in the catalog installs :ok" do
      for catalog_battery <- Catalog.all() do
        ControlServer.Repo.delete_all(SystemBattery)

        assert {:ok, _result} = Installer.install(catalog_battery.type)
      end
    end

    test "runs the postgres post hook" do
      assert 0 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert {:ok, _res} = Installer.install(:postgres)
      assert 1 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
    end

    test "runs the gitea post hook" do
      assert 0 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert {:ok, _res} = Installer.install(:gitea)
      assert 2 >= ControlServer.Repo.aggregate(PGCluster, :count, :id)
    end

    test "runs the harbor post hook" do
      assert 0 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert 0 == ControlServer.Repo.aggregate(FailoverCluster, :count, :id)
      assert {:ok, _res} = Installer.install(:harbor)
      assert 2 >= ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert 1 == ControlServer.Repo.aggregate(FailoverCluster, :count, :id)
    end

    test "installs all from system_batteries" do
      assert 0 == ControlServer.Repo.aggregate(SystemBattery, :count, :id)

      {:ok, _} =
        :test
        |> CommonCore.SystemState.SeedState.seed()
        |> then(fn %{batteries: batteries} = _state ->
          batteries
          |> Enum.map(&to_fresh_args/1)
          |> Installer.install_all()
        end)

      assert ControlServer.Repo.aggregate(SystemBattery, :count, :id) >= 4
    end
  end
end
