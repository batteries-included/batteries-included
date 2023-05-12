defmodule ControlServerWeb.CatalogBatteriesTableTest do
  use Heyya.SnapshotTest

  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery
  import ControlServerWeb.CatalogBatteriesTable

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
      catalog_batteries
      |> Enum.map(fn cb -> {cb.type, CatalogBattery.to_fresh_system_battery(cb)} end)
      |> Map.new()

    assigns = %{system_batteries: system_batteries, catalog_batteries: catalog_batteries}

    ~H"""
    <.catalog_batteries_table
      system_batteries={@system_batteries}
      catalog_batteries={@catalog_batteries}
    />
    """
  end
end
