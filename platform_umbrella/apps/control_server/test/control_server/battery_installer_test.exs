defmodule ControlServer.Batteries.InstallerTest do
  use ControlServer.DataCase

  alias ControlServer.Batteries.Catalog
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

    test "Can install every battery together" do
      Enum.each(Catalog.all(), fn cb ->
        assert {:ok, _res} = Installer.install(cb.type)
      end)
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

    test "runs the ory_hydra post hook" do
      assert 0 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert {:ok, _res} = Installer.install(:ory_hydra)
      assert 2 >= ControlServer.Repo.aggregate(PGCluster, :count, :id)
    end

    test "runs the harbor post hook" do
      assert 0 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert 0 == ControlServer.Repo.aggregate(FailoverCluster, :count, :id)
      assert {:ok, _res} = Installer.install(:harbor)
      assert 2 >= ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert 1 == ControlServer.Repo.aggregate(FailoverCluster, :count, :id)
    end
  end
end
