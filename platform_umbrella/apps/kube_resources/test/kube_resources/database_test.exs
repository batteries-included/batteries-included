defmodule KubeResources.DatabaseTest do
  use ControlServer.DataCase

  alias KubeResources.Database

  describe "Devtools workd from the BaseService" do
    test "Can materialize the internal" do
      assert map_size(Database.materialize_internal(%{})) >= 5
    end

    test "Can materialize the public" do
      assert map_size(Database.materialize_public(%{})) >= 1
    end

    test "Can materialize the common" do
      assert map_size(Database.materialize_public(%{})) >= 1
    end
  end
end
