defmodule KubeExt.CatalogTest do
  use ExUnit.Case

  alias KubeExt.Defaults.Catalog

  describe "Catalog" do
    test "Catalog.get works for all" do
      for catalog_battery <- Catalog.all() do
        # Don't check config because that's not going to be constant.
        assert catalog_battery.dependencies == Catalog.get(catalog_battery.type).dependencies
        assert catalog_battery.type == Catalog.get(catalog_battery.type).type
        assert catalog_battery.group == Catalog.get(catalog_battery.type).group
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
