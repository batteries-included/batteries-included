defmodule ControlServer.Batteries.InstallerTest do
  use ControlServer.DataCase

  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias ControlServer.Batteries.Installer

  describe "ControlServer.Batteries.Installer" do
    @tag :slow
    test "every battery in the catalog installs :ok" do
      for catalog_battery <- Catalog.all() do
        ControlServer.Repo.delete_all(SystemBattery)

        assert {:ok, _result} = Installer.install(catalog_battery.type)
      end
    end

    @tag :slow
    test "runs the postgres post hook" do
      assert 0 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert {:ok, _res} = Installer.install(:cloudnative_pg)
      assert 1 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
    end

    @tag :slow
    test "runs the gitea post hook" do
      assert 0 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert {:ok, _res} = Installer.install(:gitea)
      assert 2 >= ControlServer.Repo.aggregate(PGCluster, :count, :id)
    end

    @tag :slow
    test "installs all from system_batteries" do
      assert 0 == ControlServer.Repo.aggregate(SystemBattery, :count, :id)

      {:ok, _} =
        :everything
        |> CommonCore.StateSummary.SeedState.seed()
        |> then(fn %{batteries: batteries} = _state ->
          Installer.install_all(batteries)
        end)

      assert ControlServer.Repo.aggregate(SystemBattery, :count, :id) >= 4
    end
  end
end
