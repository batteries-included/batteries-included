defmodule KubeExt.CatalogTest do
  use ExUnit.Case

  alias KubeExt.Defaults.Catalog

  describe "Catalog" do
    test "Catalog.get works for all" do
      for catalog_battery <- Catalog.all() do
        assert catalog_battery == Catalog.get(catalog_battery.type)
      end
    end

    test "Catalog contains all good dependencies" do
      for catalog_battery <- Catalog.all() do
        for dep_type <- catalog_battery.dependencies do
          assert nil != Catalog.get(dep_type),
                 "Battery #{catalog_battery.type} dependency #{dep_type} should have a definition in the catalog"
        end
      end
    end
  end
end
