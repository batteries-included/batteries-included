defmodule CommonCore.Resources.Test.CommonCore.Resources.DatabaseTest do
  use ExUnit.Case

  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Batteries.Catalog
  alias CommonCore.StateSummary

  alias CommonCore.Resources.Postgres

  describe "CommonCore.Resources.Database" do
    test "postgres/3 contains databases" do
      spec =
        Postgres.postgres(
          %{
            name: "test",
            type: :public,
            team_name: "pg",
            num_instances: 1,
            postgres_version: "14",
            storage_size: "500M",
            databases: [%{name: "contains_test", owner: "special_owner"}]
          },
          :postgres |> Catalog.get() |> CatalogBattery.to_fresh_system_battery(),
          %StateSummary{}
        )

      databases = get_in(spec, ~w|spec databases|)
      assert map_size(databases) == 1
      assert %{"contains_test" => "special_owner"}
    end
  end
end
