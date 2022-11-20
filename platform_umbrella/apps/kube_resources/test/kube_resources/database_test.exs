defmodule Apps.KubeResources.Test.KubeResources.DatabaseTest do
  use ExUnit.Case

  alias KubeExt.Defaults.Catalog
  alias KubeExt.SystemState.StateSummary

  import KubeResources.Database

  describe "KubeResources.Database" do
    test "postgres/3 contains databases" do
      spec =
        postgres(
          %{
            name: "test",
            type: :public,
            databases: [%{name: "contains_test", owner: "special_owner"}]
          },
          Catalog.get(:database_public),
          %StateSummary{}
        )

      databases = get_in(spec, ~w|spec databases|)
      assert map_size(databases) == 1
      assert %{"contains_test" => "special_owner"}
    end
  end
end
