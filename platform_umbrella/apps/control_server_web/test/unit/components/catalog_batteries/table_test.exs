defmodule ControlServerWeb.CatalogBatteriesTableTest do
  use Heyya.SnapshotTest

  import ControlServerWeb.CatalogBatteriesTable

  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery

  component_snapshot_test "single catalog battery table" do
    catalog_batteries = Catalog.all() |> List.first() |> List.wrap()
    assigns = %{system_batteries: %{}, catalog_batteries: catalog_batteries}

    ~H"""
    <.catalog_batteries_table
      system_batteries={@system_batteries}
      catalog_batteries={@catalog_batteries}
    />
    """
  end

  component_snapshot_test "single catalog installed" do
    # Grab the first catalog battery
    catalog_batteries = Catalog.all() |> List.first() |> List.wrap()

    # Turn the catalog battery into a system battery
    # in order to simulate the battery being installed and configured in
    # the system
    system_batteries =
      Map.new(catalog_batteries, fn cb -> {cb.type, CatalogBattery.to_fresh_system_battery(cb)} end)

    assigns = %{system_batteries: system_batteries, catalog_batteries: catalog_batteries}

    ~H"""
    <.catalog_batteries_table
      system_batteries={@system_batteries}
      catalog_batteries={@catalog_batteries}
    />
    """
  end
end
