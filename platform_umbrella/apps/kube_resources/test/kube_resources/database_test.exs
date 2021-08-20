defmodule KubeResources.DatabaseTest do
  use ControlServer.DataCase, async: true

  alias KubeResources.Database

  describe "Devtools workd from the BaseService" do
    test "Can materialize" do
      assert map_size(Database.materialize(%{})) >= 5
    end
  end
end
