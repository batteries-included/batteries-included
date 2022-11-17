defmodule ControlServer.Batteries.InstallerTest do
  use ControlServer.DataCase

  alias KubeExt.Defaults.Catalog
  alias ControlServer.Batteries.SystemBattery
  alias ControlServer.Batteries.Installer
  alias ControlServer.Postgres.Cluster, as: PGCluster
  alias ControlServer.Redis.FailoverCluster

  describe "ControlServer.Batteries.Installer" do
    test "every battery in the catalog installs :ok" do
      for catalog_battery <- Catalog.all() do
        ControlServer.Repo.delete_all(ControlServer.Batteries.SystemBattery)

        assert {:ok, _result} = Installer.install(catalog_battery.type)
      end
    end

    test "runs the internal_db post hook" do
      assert 0 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert {:ok, _res} = Installer.install(:database_internal)
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
        |> KubeExt.SystemState.SeedState.seed()
        |> then(fn %{batteries: batteries} = _state ->
          Installer.install_all(batteries)
        end)

      assert ControlServer.Repo.aggregate(SystemBattery, :count, :id) >= 5
    end
  end
end
