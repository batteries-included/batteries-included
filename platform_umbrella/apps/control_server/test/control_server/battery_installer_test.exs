defmodule ControlServer.Batteries.InstallerTest do
  use ControlServer.DataCase

  import CommonCore.Factory

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
    test "runs the forgejo post hook" do
      assert 0 == ControlServer.Repo.aggregate(PGCluster, :count, :id)
      assert {:ok, _res} = Installer.install(:forgejo)
      assert 2 >= ControlServer.Repo.aggregate(PGCluster, :count, :id)
    end

    @tag :slow
    test "installs all from system_batteries" do
      assert 0 == ControlServer.Repo.aggregate(SystemBattery, :count, :id)

      :install_spec
      |> build(usage: :kitchen_sink, kube_provider: :kind, default_size: "small")
      |> then(fn spec ->
        Installer.install_all(spec.target_summary.batteries)
      end)

      assert ControlServer.Repo.aggregate(SystemBattery, :count, :id) >= 4
    end
  end
end
